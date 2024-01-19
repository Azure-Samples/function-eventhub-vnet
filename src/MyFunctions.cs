using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace Contoso.Function
{
    public static class MyFuntions
    {
        [FunctionName("TimerTriggerToEventHub")]
        public static async Task TimerTriggerToEventHubFunction([TimerTrigger("0 */5 * * * *")] TimerInfo myTimer,
            [EventHub("%EventHubName%", Connection = "EventHubConnection")] IAsyncCollector<string> outputEvents,
            ILogger log)
        {
            string messageBody = $"C# Timer trigger function executed at: {DateTime.Now}";
            log.LogInformation(messageBody);

            // Send message to output Event Hub
            await outputEvents.AddAsync(messageBody);
        }

        [FunctionName("EventHubTrigger")]
        public static async Task EventConsumerFunction([EventHubTrigger("%EventHubName%", Connection = "EventHubConnection", ConsumerGroup = "%EventHubConsumerGroup%")] EventData[] events, ILogger log)
        {
            var exceptions = new List<Exception>();

            foreach (EventData eventData in events)
            {
                try
                {
                    // Replace these two lines with your processing logic.
                    log.LogInformation($"C# Event Hub trigger function processed a message: {eventData.EventBody}");
                    await Task.Yield();
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
                throw new AggregateException(exceptions);

            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}
