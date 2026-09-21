namespace eTermin.Desktop.Models;

public class UpdateAppointmentRequest
{
    public int UserId { get; set; }
    public int SalonId { get; set; }
    public int EmployeeId { get; set; }
    public int ServiceId { get; set; }

    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }

    public string Status { get; set; } = "";

    public decimal Price { get; set; }

    public DateTime CreatedAt { get; set; }
}