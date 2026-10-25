using eTermin.Application.DTOs;
using FluentValidation;

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
            .NotEmpty()
            .WithMessage("Adresa salona je obavezna.")
            .MaximumLength(200)
            .WithMessage("Adresa može imati najviše 200 znakova.");

        RuleFor(x => x.CityId)
            .GreaterThan(0)
            .WithMessage("Grad je obavezan.");

        RuleFor(x => x.PhoneNumber)
            .NotEmpty()
            .WithMessage("Broj telefona je obavezan.")
            .MaximumLength(30)
            .WithMessage("Broj telefona može imati najviše 30 znakova.");

        RuleFor(x => x.Email)
            .NotEmpty()
            .WithMessage("Email je obavezan.")
            .EmailAddress()
            .WithMessage("Email adresa nije ispravna.");

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
}