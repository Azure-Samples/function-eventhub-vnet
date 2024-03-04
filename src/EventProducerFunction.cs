using System;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace EventProducerConsumerSample
{
    public class EventProducerFunction
    {
        [FunctionName("TimerTriggerToEventHub")]
        public static async Task TimerTriggerToEventHubFunction(
            [TimerTrigger("0 */5 * * * *")] TimerInfo myTimer,
            [EventHub("%EVENTHUB_NAME%", Connection = "EVENTHUB_CONNECTION")] IAsyncCollector<string> outputEvents,
            ILogger log)
        {
            string messageBody = $"C# Timer trigger function executed at: {DateTime.Now}";
            log.LogInformation(messageBody);

            // Send message to output Event Hub
            await outputEvents.AddAsync(messageBody);
        }
    }
}