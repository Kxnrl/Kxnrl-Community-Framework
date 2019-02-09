#if defined _A2SFirewall_ext_included
  #endinput
#endif
#define _A2SFirewall_ext_included

native bool A2SFirewall_IsClientChecked(int client);
native void A2SFirewall_GetClientTicket(int client, char[] ticket, int maxLen);

public Extension __ext_A2SFirewall = 
{
	name = "A2SFirewall",
	file = "A2SFirewall.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
