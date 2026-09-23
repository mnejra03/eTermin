namespace eTermin.Application.DTOs;

public class DashboardStatisticsDto
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

    public List<DailyReservationDto> ReservationsByDay { get; set; } = [];

    public List<ReservationStatusDto> ReservationsByStatus { get; set; } = [];

    public List<ServiceReservationDto> ReservationsByService { get; set; } = [];
}

public class DailyReservationDto
{
    public DateTime Date { get; set; }
    public int Count { get; set; }
}

public class ReservationStatusDto
{
    public string Status { get; set; } = "";
    public int Count { get; set; }
}

public class ServiceReservationDto
{
    public string ServiceName { get; set; } = "";

    public int Count { get; set; }
}