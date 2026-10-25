using eTermin.Application.DTOs;
using FluentValidation;

namespace eTermin.Application.Validators;

public class ServiceCategoryValidator : AbstractValidator<ServiceCategoryDto>
{
    public ServiceCategoryValidator()
    {
        RuleFor(category => category.Name)
            .NotEmpty()
            .WithMessage("Naziv kategorije je obavezan.")
            .MaximumLength(100)
            .WithMessage("Naziv kategorije može imati najviše 100 znakova.");

        RuleFor(category => category.Description)
            .MaximumLength(500)
            .WithMessage("Opis kategorije može imati najviše 500 znakova.");
    }
}
