using eTermin.Application.DTOs;
using FluentValidation;

namespace eTermin.Application.Validators;

public class RegisterDtoValidator : AbstractValidator<RegisterDto>
{
    public RegisterDtoValidator()
    {
        RuleFor(user => user.FirstName)
            .Must(value => !string.IsNullOrWhiteSpace(value))
            .WithMessage("Ime je obavezno.");

        RuleFor(user => user.LastName)
            .Must(value => !string.IsNullOrWhiteSpace(value))
            .WithMessage("Prezime je obavezno.");

        RuleFor(user => user.Email)
            .NotEmpty()
            .WithMessage("Email je obavezan.")
            .EmailAddress()
            .WithMessage("Email adresa nije ispravna.");

        RuleFor(user => user.Password)
            .NotEmpty()
            .WithMessage("Lozinka je obavezna.")
            .MinimumLength(6)
            .WithMessage("Lozinka mora sadržavati najmanje 6 znakova.");
    }
}
