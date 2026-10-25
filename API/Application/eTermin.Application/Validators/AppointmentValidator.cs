using eTermin.Application.DTOs;
using eTermin.Domain.Constants;
using FluentValidation;

namespace eTermin.Application.Validators;

public class AppointmentValidator : AbstractValidator<AppointmentDto>
{
    public AppointmentValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0)
            .WithMessage("UserId mora biti veći od 0.");

        RuleFor(x => x.SalonId)
            .GreaterThan(0)
            .WithMessage("SalonId mora biti veći od 0.");

        RuleFor(x => x.EmployeeId)
            .GreaterThan(0)
            .WithMessage("EmployeeId mora biti veći od 0.");

        RuleFor(x => x.ServiceId)
            .GreaterThan(0)
            .WithMessage("ServiceId mora biti veći od 0.");

        RuleFor(x => x.StartTime)
            .NotEmpty()
            .WithMessage("Početak termina je obavezan.");

        RuleFor(x => x.EndTime)
            .GreaterThan(x => x.StartTime)
            .WithMessage("Kraj termina mora biti nakon početka termina.");

        RuleFor(x => x.Status)
            .NotEmpty()
            .WithMessage("Status termina je obavezan.")
            .Must(status =>
                status == AppointmentStatuses.Pending ||
                status == AppointmentStatuses.Confirmed ||
                status == AppointmentStatuses.Cancelled ||
                status == AppointmentStatuses.Completed)
            .WithMessage(
                $"Status mora biti {AppointmentStatuses.Pending}, {AppointmentStatuses.Confirmed}, {AppointmentStatuses.Cancelled} ili {AppointmentStatuses.Completed}.");

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0)
            .WithMessage("Cijena termina ne može biti negativna.");
    }
}
