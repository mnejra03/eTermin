namespace eTermin.Application.DTOs;

public class SalonDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int EmployeeCount { get; set; }
    public int ReservationCount { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public List<SalonImageDto>? Images { get; set; }
    public bool IsActive { get; set; }
}