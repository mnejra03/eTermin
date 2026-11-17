using eTermin.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Data;

internal static class AppointmentLockExtensions
{
    public static Task<Appointment?> LockForPaymentAsync(
        this eTerminDbContext context,
        int appointmentId)
    {
        // Keep an update lock until the surrounding transaction commits. This
        // serializes payment creation/capture with appointment cancellation.
        return context.Appointments
            .FromSqlInterpolated($"""
                SELECT *
                FROM [Appointments] WITH (UPDLOCK, ROWLOCK)
                WHERE [Id] = {appointmentId}
                """)
            .FirstOrDefaultAsync();
    }
}
