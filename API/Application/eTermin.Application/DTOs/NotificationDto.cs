namespace eTermin.Application.DTOs;

public class NotificationDto
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string? UserName { get; set; }

    public int? AppointmentId { get; set; }

    public string Type { get; set; } = "General";

    public string Title { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; }
}
