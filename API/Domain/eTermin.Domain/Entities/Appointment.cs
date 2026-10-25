public class Appointment
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int SalonId { get; set; }
    public int EmployeeId { get; set; }
    public int ServiceId { get; set; }

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public string Status { get; set; } = string.Empty;

    public decimal Price { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? CancelledAt { get; set; }

    public int? CancelledByUserId { get; set; }

    public string? CancellationReason { get; set; }

    public ICollection<eTermin.Domain.Entities.AppointmentStatusHistory> StatusHistory { get; set; }
        = new List<eTermin.Domain.Entities.AppointmentStatusHistory>();
}
