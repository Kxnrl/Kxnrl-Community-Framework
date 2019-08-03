using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using WebSocketSharp;
using WebsocketRelay.IProtocol;
using static WebsocketRelay.Program;
using System.Timers;

namespace WebsocketRelay
{
    class Client
    {
        public CompressionMethod Compression
        {
            get => client.Compression;
            set => client.Compression = value;
        }

        public string KeyChain;

        const uint Client_ForwardUser = 701;
        const uint Client_HeartBeat = 702;
        const uint Client_S2S = 703;

        private WebSocket client;
        private bool AutoReconnect;
        public bool WasAuthorized;
        private Timer timer;

        private static Server relay;
        public static Server RelayProxy { set => relay = value; }

        public void Connect() => client.Connect();
        public void ConnectAsync() => client.ConnectAsync();
        public void Disconnect() => client.Close(CloseStatusCode.Normal, "Exited");
        public void DisconnectAsync() => client.CloseAsync(CloseStatusCode.Normal, "Exited");
        public void Send(string data) => client.Send(data);
        public void SendAsync(string data, Action<bool> completed) => client.SendAsync(data, completed);
        public void Dispose() => timer.Dispose();

        public Client(WebsocketSchema schema, string url, ushort port, bool autoReconnect = true, string sslhost = null)
        {
            client = new WebSocket(Enum.GetName(typeof(WebsocketSchema), schema).ToLower() + "://" + url.TrimEnd('/') + ":" + port)
            {
                Compression = CompressionMethod.Deflate,
                EmitOnPing = false,
                WaitTime = TimeSpan.FromSeconds(15)
            };

            if (schema is WebsocketSchema.WS)
            {
                client.SslConfiguration.EnabledSslProtocols = System.Security.Authentication.SslProtocols.Tls12;
                client.SslConfiguration.CheckCertificateRevocation = true;
                client.SslConfiguration.TargetHost = sslhost;
            }

            client.OnOpen += ClientHandler_OnOpen;
            client.OnClose += ClientHandler_OnClose;
            client.OnError += ClientHandler_OnError;
            client.OnMessage += ClientHandler_OnMessage;

            AutoReconnect = autoReconnect;

            timer = new Timer
            {
                AutoReset = true,
                Enabled = true,
                Interval = 30000
            };
            timer.Elapsed += Event_OnTimer;
            timer.Start();
        }

        private void Event_OnTimer(object sender, ElapsedEventArgs e)
        {
            if (client.ReadyState == WebSocketState.Open)
            {
                client.Ping();
                AppendLog(ConsoleColor.Cyan, "[Client] KeepAlive...");
            }
        }

        #region Connection Handler
        private void ClientHandler_OnOpen(object sender, EventArgs e)
        {
            WasAuthorized = false;
            client.Send("WebSocketRelay" + KeyChain);
            AppendLog(ConsoleColor.Cyan, "[Client] Authorizing...");
        }

        private void ClientHandler_OnClose(object sender, CloseEventArgs e)
        {
            AppendLog(ConsoleColor.Red, "[Client] Disconnected: {0}", e.Reason);

            if (AutoReconnect)
            {
                System.Threading.Thread.Sleep(3000);
                client.ConnectAsync();
            }
        }

        private void ClientHandler_OnError(object sender, ErrorEventArgs e)
        {
            AppendLog(ConsoleColor.DarkRed, "[Client] Error: {0} -> {1}", e.Message, e.Exception.Message);
        }
        #endregion

        private void ClientHandler_OnMessage(object sender, MessageEventArgs e)
        {
            if (e.IsBinary)
            {
                // log error
                AppendLog(ConsoleColor.Red, "[Client] Recv binary data: size: {0} bytes", e.RawData.Length);
            }

            try
            {
                dynamic recv = JObject.Parse(e.Data);

                if (recv.err != null && recv.msg != null)
                {
                    WasAuthorized = true;
                    AppendLog(ConsoleColor.Green, "[Client] Authorized. Message: {0}", recv.msg.ToString());
                    return;
                }

                if (!WasAuthorized)
                {
                    AppendLog(ConsoleColor.Red, "[Client] Recv data before authroizing: {0}", e.Data);
                    return;
                }

                var data = JsonConvert.DeserializeObject<IProtocol.Client>(e.Data);

                if (data.Data == null)
                {
                    AppendLog(ConsoleColor.Red, "[Client] Recv data with wrong format: {0}", e.Data);
                    return;
                }

                if (data.Type == Client_ForwardUser)
                {
                    relay.SendToClient(data.Data.RemoteIP, new IProtocol.Server()
                    {
                        DateTime = (uint)(DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1))).TotalSeconds,
                        SteamLId = null, // to do
                        ActionId = ActionId.HeartBeat
                    });

                    return;
                }

                AppendLog(ConsoleColor.White, "Recv Format Message:" + Environment.NewLine + e.Data);
            }
            catch (JsonException je)
            {
                AppendLog(ConsoleColor.DarkMagenta, "[Client] Json Parser Exception: {0}", je.Message);
                AppendLog(ConsoleColor.White, "Recv Message: {0}{1}", Environment.NewLine, e.Data);
            }
            catch (Exception ex)
            {
                AppendLog(ConsoleColor.DarkMagenta, "[Client] Handler Exception: {0}", ex.Message);
                AppendLog(ConsoleColor.White, "Recv Message: {0}{1}", Environment.NewLine, e.Data);
            }
        }
    }
}
