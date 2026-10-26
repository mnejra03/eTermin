using eTermin.Application.DTOs;
using FluentValidation;
using System.Text.RegularExpressions;

namespace eTermin.Application.Validators;

public class SalonValidator : AbstractValidator<SalonDto>
{
    public SalonValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .WithMessage("Naziv salona je obavezan.")
            .MaximumLength(100)
            .WithMessage("Naziv salona može imati najviše 100 znakova.");

        RuleFor(x => x.Description)
            .MaximumLength(500)
            .WithMessage("Opis salona može imati najviše 500 znakova.");

        RuleFor(x => x.Address)
            .Cascade(CascadeMode.Stop)
            .NotEmpty()
            .WithMessage("Adresa salona je obavezna.")
            .Must(IsValidAddress)
            .WithMessage("Unesite ulicu i broj, npr. Maršala Tita 25.")
            .MaximumLength(200)
            .WithMessage("Adresa može imati najviše 200 znakova.");

        RuleFor(x => x.CityId)
            .GreaterThan(0)
            .WithMessage("Grad je obavezan.");

        RuleFor(x => x.PhoneNumber)
            .Cascade(CascadeMode.Stop)
            .NotEmpty()
            .WithMessage("Broj telefona je obavezan.")
            .Must(IsValidPhoneNumber)
            .WithMessage("Unesite broj kao 061 123 456 ili +387 61 123 456.")
            .MaximumLength(30)
            .WithMessage("Broj telefona može imati najviše 30 znakova.");

        RuleFor(x => x.Email)
            .Cascade(CascadeMode.Stop)
            .NotEmpty()
            .WithMessage("Email je obavezan.")
            .EmailAddress()
            .WithMessage("Email adresa nije ispravna.")
            .Must(IsValidEmail)
            .WithMessage("Unesite email u obliku ime@domena.ba.")
            .MaximumLength(254)
            .WithMessage("Email adresa može imati najviše 254 znaka.");

        RuleFor(x => x.ImageUrl)
            .MaximumLength(500)
            .WithMessage("URL slike može imati najviše 500 znakova.");

        RuleForEach(x => x.Images)
            .ChildRules(image =>
            {
                image.RuleFor(x => x.ImageUrl)
                    .NotEmpty()
                    .WithMessage("URL slike salona je obavezan.")
                    .MaximumLength(1000)
                    .WithMessage("URL slike može imati najviše 1000 znakova.");
            });
    }

    private static bool IsValidPhoneNumber(string? phoneNumber)
    {
        if (string.IsNullOrWhiteSpace(phoneNumber))
            return true;

        var normalized = Regex.Replace(phoneNumber, @"[\s()./-]", string.Empty);
        return Regex.IsMatch(normalized, @"^(?:0\d{7,9}|\+387\d{7,9})$");
    }

    private static bool IsValidAddress(string? address)
    {
        if (string.IsNullOrWhiteSpace(address))
            return false;

        var trimmed = address.Trim();
        return trimmed.Length >= 5 &&
               trimmed.Any(char.IsLetter) &&
               trimmed.Any(char.IsDigit);
    }

    private static bool IsValidEmail(string email) =>
        Regex.IsMatch(email, @"^[^\s@]+@[^\s@]+\.[^\s@]+$");
}
