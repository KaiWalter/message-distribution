namespace func_distributor
{
    public class Order
    {
        public int OrderId { get; set; }
        public string Description { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public Delivery Delivery { get; set; }
    }
}
