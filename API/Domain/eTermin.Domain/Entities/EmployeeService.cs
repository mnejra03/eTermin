namespace eTermin.Domain.Entities;

public class EmployeeService
{
    public int EmployeeId { get; set; }

    public int ServiceId { get; set; }

    public Employee Employee { get; set; } = null!;

    public Service Service { get; set; } = null!;
}