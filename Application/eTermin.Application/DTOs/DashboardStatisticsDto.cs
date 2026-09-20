namespace eTermin.Application.DTOs;

public class DashboardStatisticsDto
{
    public int TotalAppointments { get; set; }
    public int TotalUsers { get; set; }
    public int TotalSalons { get; set; }
    public decimal TotalRevenue { get; set; }

    public string? MostPopularService { get; set; }
    public int MostPopularServiceCount { get; set; }
}