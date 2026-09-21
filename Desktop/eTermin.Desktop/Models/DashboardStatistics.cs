namespace eTermin.Desktop.Models;

public class DashboardStatistics
{
    public int TotalAppointments { get; set; }
    public int TotalUsers { get; set; }
    public int TotalSalons { get; set; }
    public decimal TotalRevenue { get; set; }
    public string MostPopularService { get; set; } = string.Empty;
    public int MostPopularServiceCount { get; set; }
}