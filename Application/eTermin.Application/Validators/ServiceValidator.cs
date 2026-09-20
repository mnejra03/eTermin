using eTermin.Application.DTOs;
using FluentValidation;

namespace eTermin.Application.Validators;

public class ServiceValidator : AbstractValidator<ServiceDto>
{
    public ServiceValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .WithMessage("Naziv usluge je obavezan.")
            .MaximumLength(100)
            .WithMessage("Naziv usluge može imati najviše 100 znakova.");

        RuleFor(x => x.Description)
            .MaximumLength(500)
            .WithMessage("Opis usluge može imati najviše 500 znakova.");

        RuleFor(x => x.SalonId)
            .GreaterThan(0)
            .WithMessage("SalonId mora biti veći od 0.");

        RuleFor(x => x.DurationInMinutes)
            .GreaterThan(0)
            .WithMessage("Trajanje usluge mora biti veće od 0 minuta.");

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Cijena usluge ne može biti negativna.");
    }
}