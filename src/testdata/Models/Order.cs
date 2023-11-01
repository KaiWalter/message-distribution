using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace Models
{
    public class Order
    {
        public int OrderId { get; set; }
        public Guid OrderGuid { get; set; }
        public string? Description { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public Delivery Delivery { get; set; }

        public List<OrderItem>? Items { get; set; }
    }

    public class OrderItem
    {
        public int OrderItemId { get; set; }
        public string? SKU { get; set; }
        public int Quantity { get; set; }
    }

    public class DaprBulkOrder
    {
        [JsonPropertyName("entryId")]
        public string? EntryId { get; set; }
        [JsonPropertyName("event")]
        public Order? Event { get; set; }
        [JsonPropertyName("contentType")]
        public string? ContentType { get; set; }
    }
}
