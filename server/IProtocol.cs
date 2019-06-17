using Newtonsoft.Json;
using System;

namespace WebsocketRelay.IProtocol
{
    enum ActionId
    {
        HandShake,
        HeartBeat
    }

    class Server
    {
        [JsonProperty("DateTime")]
        public uint DateTime;

        [JsonProperty("SteamLId")]
        public string SteamLId;

        [JsonProperty("Action")]
        [JsonConverter(typeof(ActionEnumConverter))]
        public ActionId ActionId;
    }

    public class ActionEnumConverter : JsonConverter
    {
        public override bool CanConvert(Type objectType)
        {
            return objectType == typeof(ActionId);
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            return Enum.Parse(typeof(ActionId), existingValue.ToString());
        }

        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {
            serializer.Serialize(writer, Enum.GetName(typeof(ActionId), (ActionId)value));
        }
    }

    class Client
    {
        [JsonProperty("Message_Type")]
        public uint Type;

        [JsonProperty("Message_Data")]
        public Message_Data Data;
    }

    public class Message_Data
    {
        [JsonProperty("ip")]
        public string RemoteIP;

        [JsonProperty("steamid")]
        public string SteamId;

        [JsonProperty("time")]
        public uint Timestamp;

        [JsonProperty("count")]
        public uint Count;

        [JsonProperty("alives")]
        public uint Onlines;
    }
}
