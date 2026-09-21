namespace eTermin.Desktop.Models;

public class AppointmentListItem
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int SalonId { get; set; }

    public int EmployeeId { get; set; }

    public int ServiceId { get; set; }

    public string UserName { get; set; } = "";

    public string SalonName { get; set; } = "";

    public string EmployeeName { get; set; } = "";

    public string ServiceName { get; set; } = "";

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public string Status { get; set; } = "";

    public decimal Price { get; set; }

    public DateTime CreatedAt { get; set; }
}