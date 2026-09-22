namespace eTermin.Desktop.Models;

public class CreateSalonRequest
{
    public string Name { get; set; } = "";

    public string Description { get; set; } = "";

    public string Address { get; set; } = "";

    public string City { get; set; } = "";

    public string PhoneNumber { get; set; } = "";

    public string Email { get; set; } = "";

    public string ImageUrl { get; set; } = "";

    public bool IsActive { get; set; }
}