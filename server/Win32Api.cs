using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

namespace WebsocketRelay.Win32Api
{
    class Profile
    {
        private string configFile = null;

        public Profile(string file) => configFile = file;

        public string GetString(string section, string key, string defaultValue = null)
        {
            if (configFile == null)
                throw new Win32Exception("Configuration file not specified");

            var sb = new StringBuilder(1024);
            GetPrivateProfileString(section, key, defaultValue, sb, 1024, configFile);
            return sb.Length == 0 ? null : sb.ToString();
        }

        public bool SetString(string section, string key, string val)
        {
            if (configFile == null)
                throw new Win32Exception("Configuration file not specified");

            return WritePrivateProfileString(section, key, val, configFile);
        }

        public int GetInt(string section, string key)
        {
            var data = GetString(section, key);
            if (data == null)
                return 0;

            if (!int.TryParse(data, out int ret))
                return 0;

            return ret;
        }

        public bool SetInt(string section, string key, int val)
        {
            return SetString(section, key, val.ToString());
        }

        public bool GetBool(string section, string key)
        {
            var data = GetString(section, key);
            if (data == null)
                return false;

            if (!bool.TryParse(data, out bool ret))
                return false;

            return ret;
        }

        public bool SetBool(string section, string key, bool val)
        {
            return SetString(section, key, val.ToString());
        }

        [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool WritePrivateProfileString(string section, string key, string val, string filepath);

        [DllImport("kernel32.dll")]
        private static extern int GetPrivateProfileString(string section, string key, string def, StringBuilder retval, int size, string filePath);
    }
}
