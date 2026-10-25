namespace eTermin.Application.DTOs;

public class EmployeeDto
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string PhoneNumber { get; set; } = string.Empty;

    public string Position { get; set; } = string.Empty;

    public List<EmployeeWorkingHourDto> WorkingSchedule { get; set; } = new();

    public bool IsActive { get; set; }

    public List<int> ServiceIds { get; set; } = new();
}
