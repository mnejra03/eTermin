namespace eTermin.Domain.Entities;

public class Payment
{
    public int Id { get; set; }

    public int AppointmentId { get; set; }

    public decimal Amount { get; set; }

    public string PaymentMethod { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;

    public string TransactionId { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}