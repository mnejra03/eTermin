namespace eTermin.Application.DTOs;

public class EmployeeWorkingHourDto
{
    public DayOfWeek DayOfWeek { get; set; }

    public TimeSpan StartTime { get; set; }

    public TimeSpan EndTime { get; set; }
}
