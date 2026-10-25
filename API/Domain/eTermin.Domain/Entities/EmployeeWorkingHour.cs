namespace eTermin.Domain.Entities;

public class EmployeeWorkingHour
{
    public int Id { get; set; }

    public int EmployeeId { get; set; }

    public DayOfWeek DayOfWeek { get; set; }

    public TimeSpan StartTime { get; set; }

    public TimeSpan EndTime { get; set; }
}
