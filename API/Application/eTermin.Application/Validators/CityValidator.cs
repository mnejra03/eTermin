using eTermin.Application.DTOs;
using FluentValidation;

namespace eTermin.Application.Validators;

public class CityValidator : AbstractValidator<CityDto>
{
    public CityValidator()
    {
        RuleFor(city => city.Name)
            .NotEmpty()
            .WithMessage("Naziv grada je obavezan.")
            .MaximumLength(100)
            .WithMessage("Naziv grada može imati najviše 100 znakova.");
    }
}
