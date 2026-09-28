namespace eTermin.Application.DTOs;

public class CreateAppointmentDto
{
    public int SalonId { get; set; }

    public int EmployeeId { get; set; }

    public int ServiceId { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public string Status { get; set; } = string.Empty;

    public decimal Price { get; set; }
}