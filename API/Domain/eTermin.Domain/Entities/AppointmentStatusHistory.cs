namespace eTermin.Domain.Entities;

public class AppointmentStatusHistory
{
    public int Id { get; set; }

    public int AppointmentId { get; set; }

    public Appointment Appointment { get; set; } = null!;

    public string? PreviousStatus { get; set; }

    public string NewStatus { get; set; } = string.Empty;

    public int ChangedByUserId { get; set; }

    public DateTime ChangedAt { get; set; }
}
