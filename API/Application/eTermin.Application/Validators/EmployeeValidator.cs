using System.Text.RegularExpressions;
using eTermin.Application.DTOs;
using FluentValidation;

namespace eTermin.Application.Validators;

public sealed class EmployeeValidator : AbstractValidator<EmployeeDto>
{
    public EmployeeValidator()
    {
        RuleFor(employee => employee.SalonId)
            .GreaterThan(0)
            .WithMessage("Odaberite salon za zaposlenika.");

        RuleFor(employee => employee.FirstName)
            .Cascade(CascadeMode.Stop)
            .Must(value => !string.IsNullOrWhiteSpace(value))
            .WithMessage("Ime zaposlenika je obavezno.")
            .MaximumLength(100)
            .WithMessage("Ime može imati najviše 100 znakova.");

        RuleFor(employee => employee.LastName)
            .Cascade(CascadeMode.Stop)
            .Must(value => !string.IsNullOrWhiteSpace(value))
            .WithMessage("Prezime zaposlenika je obavezno.")
            .MaximumLength(100)
            .WithMessage("Prezime može imati najviše 100 znakova.");

        RuleFor(employee => employee.Email)
            .Cascade(CascadeMode.Stop)
            .Must(value => !string.IsNullOrWhiteSpace(value))
            .WithMessage("Email zaposlenika je obavezan.")
            .Must(IsValidEmail)
            .WithMessage("Unesite email u obliku ime@domena.ba.")
            .MaximumLength(254)
            .WithMessage("Email adresa može imati najviše 254 znaka.");

        RuleFor(employee => employee.PhoneNumber)
            .Cascade(CascadeMode.Stop)
            .Must(value => !string.IsNullOrWhiteSpace(value))
            .WithMessage("Broj telefona zaposlenika je obavezan.")
            .Must(IsValidPhoneNumber)
            .WithMessage("Unesite broj kao 061 123 456 ili +387 61 123 456.")
            .MaximumLength(30)
            .WithMessage("Broj telefona može imati najviše 30 znakova.");

        RuleFor(employee => employee.Position)
            .Cascade(CascadeMode.Stop)
            .Must(value => !string.IsNullOrWhiteSpace(value))
            .WithMessage("Pozicija zaposlenika je obavezna.")
            .MaximumLength(100)
            .WithMessage("Pozicija može imati najviše 100 znakova.");
    }

    private static bool IsValidEmail(string email) =>
        Regex.IsMatch(email, @"^[^\s@]+@[^\s@]+\.[^\s@]+$");

    private static bool IsValidPhoneNumber(string? phoneNumber)
    {
        if (string.IsNullOrWhiteSpace(phoneNumber))
            return false;

        var normalized = Regex.Replace(phoneNumber, @"[\s()./-]", string.Empty);
        return Regex.IsMatch(normalized, @"^(?:0\d{7,9}|\+387\d{7,9})$");
    }
}
