using Kerberos.NET;
using Kerberos.NET.Configuration;
using Kerberos.NET.Credentials;
using Kerberos.NET.Entities;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace KerbTest
{
    internal class Program
    {
        static int Main(string[] args)
        {
            return MainAsync(args).Result;
        }

        static async Task<int> MainAsync(string[] args)
        {
            //client for test user 
            KerberosPasswordCredential credUser = new KerberosPasswordCredential("Dev", "Password1", "forest2.net");
            var clientUser = new Kerberos.NET.Client.KerberosClient();
            //clientUser.Configuration.Defaults.DnsLookupKdc = false;
            //clientUser.Configuration.Realms["FOREST2.NET"].Kdc.Add("F2DC1.FOREST2.NET:88");
            //clientUser.Configuration.Realms["FOREST1.NET"].Kdc.Add("F1DC1.FOREST1.NET:88");
            await clientUser.Authenticate(credUser);

            var tgsUserForKerbTestService = await clientUser.GetServiceTicket("http/KERBTEST.FOREST2.NET");
            //var tgsUserForF1SQL1 = await clientUser.GetServiceTicket("MSSQLSvc/F1SQL1.forest1.net");
            //var tgsUserForF1SQL2 = await clientUser.GetServiceTicket("MSSQLSvc/F2SQL1.forest2.net");

            //----------------------------------------------------------------------------------------------------

            KerberosPasswordCredential credService = new KerberosPasswordCredential("KerbTestService", "Password9", "forest2.net");
            var clientService = new Kerberos.NET.Client.KerberosClient(Krb5Config.Default());
            //clientService.Configuration.Defaults.DnsLookupKdc = false;
            //clientService.Configuration.Realms["FOREST2.NET"].Kdc.Add("F2DC1.FOREST2.NET:88");
            //clientService.Configuration.Realms["FOREST1.NET"].Kdc.Add("F1DC1.FOREST1.NET:88");
            //clientService.Configuration.CaPaths.Add("FOREST1.NET", new Dictionary<string, string>() { { "FOREST2.COM", "." } });
            //clientService.Configuration.CaPaths.Add("FOREST2.NET", new Dictionary<string, string>() { { "FOREST1.COM", "." } });

            await clientService.Authenticate(credService);

            //when using protocol transition
            //var s4uSelf = await clientService.GetServiceTicket("http/KERBTEST.FOREST2.NET", ApOptions.MutualRequired, "Dev");

            var rst = new RequestServiceTicket();
            rst.ServicePrincipalName = "MSSQLSvc/F2SQL1.forest2.net";
            rst.S4uTicket = tgsUserForKerbTestService.Ticket;
            var tgsServiceForF2SQL1 = await clientService.GetServiceTicket(rst);

            rst = new RequestServiceTicket();
            rst.ServicePrincipalName = "MSSQLSvc/F1SQL1.forest1.net";
            rst.S4uTicket = tgsUserForKerbTestService.Ticket;
            var tgsServiceForF1SQL1 = await clientService.GetServiceTicket(rst);

            return 0;

        }
    }
}
