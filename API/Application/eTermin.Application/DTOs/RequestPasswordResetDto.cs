using System.ComponentModel.DataAnnotations;

namespace eTermin.Application.DTOs;

public class RequestPasswordResetDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
}
