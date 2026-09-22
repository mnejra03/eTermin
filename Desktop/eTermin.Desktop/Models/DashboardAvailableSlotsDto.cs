namespace eTermin.Desktop.Models;

public class DashboardAvailableSlotsDto
{
    public int AvailableSlots { get; set; }
    public int TotalSlots { get; set; }
    public int OccupiedSlots { get; set; }
    public int Percentage { get; set; }
}