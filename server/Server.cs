using Fleck;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Security.Cryptography.X509Certificates;
using WebsocketRelay.IProtocol;
using static WebsocketRelay.Program;

namespace WebsocketRelay
{
    class Server
    {
        const uint Client_ForwardUser = 701;
        const uint Client_HeartBeat   = 702;
        const uint Client_S2S         = 703;

        public int Onlines { get => clients.Count; }

        private List<IWebSocketConnection>   clients;
        private Dictionary<string, DateTime> banList;
        private Dictionary<string, DateTime> avgTime;
        private Dictionary<string, uint>     clCount;
        private WebSocketServer wserver;

        private static Client relay;
        public static Client RelayProxy { set => relay = value; }

        public Server(WebsocketSchema schema, ushort port)
        {
            clients = new List<IWebSocketConnection>();
            banList = new Dictionary<string, DateTime>();
            avgTime = new Dictionary<string, DateTime>();
            clCount = new Dictionary<string, uint>();
            wserver = new WebSocketServer(Enum.GetName(typeof(WebsocketSchema), schema).ToLower() + "://" + "0.0.0.0" + ":" + port);
            InitLogger();
        }

        public Server(WebsocketSchema schema, ushort port, X509Certificate2 ssl)
        {
            clients = new List<IWebSocketConnection>();
            banList = new Dictionary<string, DateTime>();
            avgTime = new Dictionary<string, DateTime>();
            clCount = new Dictionary<string, uint>();
            wserver = new WebSocketServer(Enum.GetName(typeof(WebsocketSchema), schema).ToLower() + "://" + "0.0.0.0" + ":" + port)
            {
                Certificate = ssl,
                EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12 | System.Security.Authentication.SslProtocols.Tls11 | System.Security.Authentication.SslProtocols.Tls
            };
            InitLogger();
        }

        public void InitLogger()
        {
            FleckLog.LogAction = (level, message, ex) =>
            {
                switch (level)
                {
                    case LogLevel.Error:
                        AppendLog(ConsoleColor.DarkRed, message + (ex != null ? Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace : ""));
                        break;
                    case LogLevel.Warn:
                        AppendLog(ConsoleColor.Red, message + (ex != null ? Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace : ""));
                        break;
                    case LogLevel.Info:
                        AppendLog(ConsoleColor.Gray, message + (ex != null ? Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace : ""));
                        break;
                    //case LogLevel.Debug:
                    //    AppendLog(ConsoleColor.White, message + (ex != null ? Environment.NewLine + ex.Message + Environment.NewLine + ex.StackTrace : ""));
                    //    break;
                }
            };
        }

        public void Start(bool autoRestart = true)
        {
            wserver.RestartAfterListenError = autoRestart;

            wserver.Start(socket =>
            {
                socket.OnOpen = () => Event_OnOpen(socket);
                socket.OnMessage = message => Event_OnMessage(socket, message);
                socket.OnBinary = binary => Event_OnBinary(socket, binary);
                socket.OnError = error => Event_OnError(socket, error);
                socket.OnClose = () => Event_OnClose(socket);
            });
        }

        public void Stop()
        {
            foreach (var socket in clients)
            {
                socket.Close();
            }
            clients.Clear();
            wserver.Dispose();
        }

        #region Client Socket Event
        private void Event_OnMessage(IWebSocketConnection socket, string message)
        {
            var ptr = GetClientAddress(socket);
            clCount[ptr]++; 

            try
            {
                var data = JsonConvert.DeserializeObject<IProtocol.Server>(message);
                

                if (data.ActionId is ActionId.HandShake)
                {
                    socket.Send(JsonConvert.SerializeObject(new IProtocol.Server()
                    {
                        DateTime = (uint)(DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1))).TotalSeconds,
                        SteamLId = null, // to do
                        ActionId = ActionId.HandShake
                    }));
                    return;
                } else 
                if (data.ActionId is ActionId.HeartBeat)
                {
                    var ip = GetClientAddress(socket, false);
                    relay.Send(JsonConvert.SerializeObject(new IProtocol.Client()
                    {
                        Type = Client_HeartBeat,
                        Data = new Message_Data()
                        {
                            RemoteIP = ip,
                            SteamId = null,
                            Timestamp = (uint)(DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1))).TotalSeconds,
                            Onlines = (uint)(DateTime.Now - avgTime[ip]).TotalMinutes,
                            Count = clCount[ptr]
                        }
                    }));
                    return;
                }

                AppendLog(ConsoleColor.White, "Recv Format Message:" + Environment.NewLine + message);
            }
            catch (JsonSerializationException jse)
            {
                AppendLog(ConsoleColor.DarkMagenta, "[Server] Json Serialization Exception: {0}", jse.Message);
                AppendLog(ConsoleColor.White, "Recv Message: {0}{1}", Environment.NewLine, message);
                BanClient(socket, "Sent wrong format data.");
            }
            catch (JsonException je)
            {
                AppendLog(ConsoleColor.DarkMagenta, "[Server] Json Parser Exception: {0}", je.Message);
                AppendLog(ConsoleColor.White, "Recv Message: {0}{1}" + Environment.NewLine + message);
                BanClient(socket, "Sent wrong format data.");
            }
            catch (Exception ex)
            {
                AppendLog(ConsoleColor.DarkMagenta, "[Server] Handler Exception: {0}", ex.Message);
                AppendLog(ConsoleColor.White, "Recv Message: {0}{1}", Environment.NewLine, message);
            }
        }

        private void Event_OnBinary(IWebSocketConnection socket, byte[] binary)
        {
            BanClient(socket, "Sent binary data.");
        }

        private void Event_OnOpen(IWebSocketConnection socket)
        {
            var ip = GetClientAddress(socket, false);
            if (banList.ContainsKey(ip))
            {
                if (DateTime.Now < banList[ip])
                {
                    banList[ip] = DateTime.Now.AddSeconds(900);
                    socket.Close();
                    return;
                }
            }
            ip = GetClientAddress(socket);
            clients.Add(socket);
            clCount[ip] = 0;
            avgTime[ip] = DateTime.Now;
            AppendLog(ConsoleColor.Green, "[Server] [{0}] Conntected.", ip);
        }

        private void Event_OnError(IWebSocketConnection socket, Exception e)
        {
            clients.Remove(socket);
            AppendLog(ConsoleColor.DarkRed, "[Server] [{0}] Error: {1}", GetClientAddress(socket), e.Message);
        }

        private void Event_OnClose(IWebSocketConnection socket)
        {
            clients.Remove(socket);
            AppendLog(ConsoleColor.Yellow, "[Server] [{0}] Disconntected.", GetClientAddress(socket));
        }
        #endregion

        #region uitls
        private string GetClientAddress(IWebSocketConnection socket, bool includePort = true)
        {
            return socket.ConnectionInfo.ClientIpAddress + (includePort ? ":" + socket.ConnectionInfo.ClientPort : "");
        }

        private void BanClient(IWebSocketConnection socket, string reason)
        {
            var ip = GetClientAddress(socket, false);
            banList[ip] = DateTime.Now.AddSeconds(900);
            socket.Close();
            clients.Remove(socket);
            AppendLog(ConsoleColor.DarkMagenta, "[Server] [{0}] has been banned. Reason: {1}", ip, reason);
        }

        public void SendToClient(string remoteIp, IProtocol.Server data)
        {
            foreach (var client in clients)
            {
                if (GetClientAddress(client).Contains(remoteIp))
                {
                    client.Send(JsonConvert.SerializeObject(data));
                }
            }
        }
        #endregion
    }
}
