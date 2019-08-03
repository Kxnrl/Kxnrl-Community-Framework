using System;
using System.IO;
using System.Security.Cryptography.X509Certificates;
using System.Threading;
using WebsocketRelay.Win32Api;

namespace WebsocketRelay
{
    class Program
    {
        private static Client Client;
        private static Server Server;

        static void Main(string[] args)
        {
            Console.Title = "Kxnrl Community Framework Websocket Relay";

            var path = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            var profile = new Profile(Path.Combine(path, "config.cfg"));

            /*================================================
             *              Client Configs Start      
             *================================================*/
            var keychain = profile.GetString("Relay.Client", "KeyChain");
            if (keychain == null)
            {
                profile.SetString("Relay.Client", "KeyChain", "Please setup KeyChain.");
            }
            var relaycli = profile.GetString("Relay.Client", "Host");
            if (relaycli == null)
            {
                profile.SetString("Relay.Client", "Host", "Please setup Remote Server Adress. e.g. 127.0.0.1");
            }
            var rcliport = profile.GetString("Relay.Client", "Port");
            if (rcliport == null)
            {
                profile.SetString("Relay.Client", "Port", "Please setup Remote Server Port. e.g. 27015");
            }
            var rcliscma = profile.GetString("Relay.Client", "Schema");
            if (rcliscma == null)
            {
                profile.SetString("Relay.Client", "Schema", "Please setup Remote Server Schema. e.g. WS or WSS");
            }
            /*================================================
             *              Client Configs End       
             *================================================*/
            Client = new Client((WebsocketSchema)Enum.Parse(typeof(WebsocketSchema), rcliscma, true), relaycli, ushort.Parse(rcliport))
            {
                KeyChain = keychain,
            };

            /*================================================
             *              Server Configs Start      
             *================================================*/
            var rsrvport = profile.GetString("Relay.Server", "Port");
            if (rsrvport == null)
            {
                profile.SetString("Relay.Server", "Port", "Please setup Port for listener. e.g. 27015");
            }
            var rsrvscma = profile.GetString("Relay.Server", "Schema");
            if (rsrvscma == null)
            {
                profile.SetString("Relay.Server", "Schema", "Please setup Schema for listener. e.g. WS or WSS");
            }
            var rsslfile = profile.GetString("Relay.Server", "SSLCertificateFile");
            if (rsslfile == null)
            {
                profile.SetString("Relay.Server", "SSLCertificateFile", "Please setup SSL Certificate. e.g. kxnrl_com.pfx");
            }
            var rsslpswd = profile.GetString("Relay.Server", "SSLCertificateFilePassword");
            if (rsslpswd == null)
            {
                profile.SetString("Relay.Server", "SSLCertificateFilePassword", "Please setup password of SSL Certificate. e.g. fysnmsl");
            }
            /*================================================
             *              Server Configs End       
             *================================================*/
            Server = !File.Exists(Path.Combine(path, rsslfile)) ? new Server((WebsocketSchema)Enum.Parse(typeof(WebsocketSchema), rsrvscma, true), ushort.Parse(rsrvport)) : new Server((WebsocketSchema)Enum.Parse(typeof(WebsocketSchema), rsrvscma, true), ushort.Parse(rsrvport), new X509Certificate2(Path.Combine(path, rsslfile), rsslpswd));

            // Relay Proxy
            Server.RelayProxy = Client;
            Client.RelayProxy = Server;

            // Start
            Client.ConnectAsync();
            Server.Start();

            // Update Thread
            new Thread(() =>
            {
                loop:
                    Thread.Sleep(1000);
                    Console.Title = "[Relay]   RemoteServer: " + (Client.WasAuthorized ? "Online" : "Offline") + "    " + "LocalServer: " + Server.Onlines + " Users";
                    goto loop;
            })
            {
                Priority = ThreadPriority.Lowest,
                IsBackground = true,
                Name = "Update Status",
            }.Start();

            // ?
            while(Console.ReadKey(true).Key != ConsoleKey.Escape)
            {
                Client.Disconnect();
                Client.Dispose();
                Server.Stop();
                Environment.Exit(0);
            }
        }

        public static void AppendLog(ConsoleColor color, string buffer, params object[] args)
        {
            var c = Console.ForegroundColor;
            Console.ForegroundColor = color;
            Console.WriteLine(buffer, args);
            Console.ForegroundColor = c;
        }
    }
}
