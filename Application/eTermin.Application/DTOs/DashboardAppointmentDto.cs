namespace eTermin.Application.DTOs;

public class DashboardAppointmentDto
{
    public int Id { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string SalonName { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal Price { get; set; }
}