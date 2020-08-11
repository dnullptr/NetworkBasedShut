using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net.NetworkInformation;
using System.Diagnostics;
using System.Threading;

namespace NetworkBasedShut
{
    class Program
    {
        static void Main(string[] args)
        {
            long Curr=0, Before=0;
            int Times=0,TimesLimit,SecUntilShut;
            int speed,adapter=0;
            bool Active=true;
            Console.WriteLine("Welcome to NetworkBasedShut :)\n");
            Console.WriteLine("Insert Speed Threshold (in KB/s):");
            speed = int.Parse(Console.ReadLine());
            Console.WriteLine("Insert Times allowed to survive less than {0}KB/s without shutdown:",speed);
            TimesLimit = int.Parse(Console.ReadLine());
            Console.WriteLine("Insert Seconds until Shutdown , when policy met:");
            SecUntilShut = int.Parse(Console.ReadLine());

            speed *= 1000; //conv to bytes per sec

            if (!NetworkInterface.GetIsNetworkAvailable())
                return;

            NetworkInterface[] interfaces
                = NetworkInterface.GetAllNetworkInterfaces();

            while (Active)
            {

                    Before = interfaces[adapter].GetIPv4Statistics().BytesReceived;

                    /*Console.WriteLine("    Bytes Sent: {0}",
                        interfaces[adapter].GetIPv4Statistics().BytesSent);*/
                    Console.WriteLine("    Bytes Received Before : {0}",
                        Before);
                Thread.Sleep(1000);
                    Curr = interfaces[adapter].GetIPv4Statistics().BytesReceived;
                Console.WriteLine("    Bytes Received After : {0}",
                       Curr);

                if (Curr < (Before + speed)) //if curr is not better than before + speed then punish
                    {
                        Times++;
                        Console.WriteLine("{0} of {1} Times that the policy met", Times,TimesLimit);
                    }
                        
                
                

                if (Times >= TimesLimit)
                {
                    Process cmd = new Process();
                    cmd.StartInfo.FileName = "cmd.exe";
                    cmd.StartInfo.RedirectStandardInput = true;
                    cmd.StartInfo.RedirectStandardOutput = true;
                    cmd.StartInfo.CreateNoWindow = true;
                    cmd.StartInfo.UseShellExecute = false;
                    cmd.Start();
                    cmd.StandardInput.WriteLine("shutdown -s -t " + SecUntilShut);
                    Console.WriteLine("Bye Bye, Sending Shutdown now..");
                    Active = !Active;
                    
                }
            }
            Console.ReadLine();
        }
    }
}
