namespace eTermin.Application.DTOs;

public class AppointmentStatusHistoryDto
{
    public int Id { get; set; }

    public string? PreviousStatus { get; set; }

    public string NewStatus { get; set; } = string.Empty;

    public int ChangedByUserId { get; set; }

    public string ChangedByName { get; set; } = string.Empty;

    public DateTime ChangedAt { get; set; }
}
