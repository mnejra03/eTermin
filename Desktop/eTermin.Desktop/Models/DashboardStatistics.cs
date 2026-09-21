namespace eTermin.Desktop.Models;

public class DashboardStatistics
{
    public int TotalAppointments { get; set; }

    public int TotalUsers { get; set; }

    public int TotalSalons { get; set; }

    public decimal TotalRevenue { get; set; }

    public string? MostPopularService { get; set; }

    public int MostPopularServiceCount { get; set; }

    public string? MostActiveUser { get; set; }

    public int MostActiveUserCount { get; set; }

    public string? MostActiveSalon { get; set; }

    public int MostActiveSalonCount { get; set; }

    public List<DailyReservation> ReservationsByDay { get; set; } = [];

    public List<ReservationStatus> ReservationsByStatus { get; set; } = [];
}

public class DailyReservation
{
    public DateTime Date { get; set; }

    public int Count { get; set; }
}

public class ReservationStatus
{
    public string Status { get; set; } = "";

    public int Count { get; set; }
}