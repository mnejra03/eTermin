using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Domain.Entities;
using eTermin.Domain.StateMachines;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class AppointmentService : IAppointmentService
{
    private readonly eTerminDbContext _context;

    public AppointmentService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<AppointmentDto>> GetAllAsync(
        int page,
        int pageSize)
    {
       return await _context.Appointments
    .Select(a => new AppointmentDto
    {
        Id = a.Id,
        UserId = a.UserId,
        SalonId = a.SalonId,
        EmployeeId = a.EmployeeId,
        ServiceId = a.ServiceId,
        StartTime = a.StartTime,
        EndTime = a.EndTime,
        Status = a.Status,
        Price = a.Price,
        IsPaid = _context.Payments.Any(p =>
            p.AppointmentId == a.Id && p.Status == PaymentStatuses.Completed),
        CreatedAt = a.CreatedAt,
        CancelledAt = a.CancelledAt,
        CancelledByUserId = a.CancelledByUserId,
        CancellationReason = a.CancellationReason
    })
    .OrderBy(a => a.StartTime)
    .ThenBy(a => a.Id)
    .ToPagedResultAsync(page, pageSize);
    }

    public async Task<PagedResult<AppointmentListDto>> GetAllForListAsync(
        int page,
        int pageSize)
    {
        return await _context.Appointments
            .Select(a => new AppointmentListDto
            {
                Id = a.Id,

                UserId = a.UserId,

                SalonId = a.SalonId,

                EmployeeId = a.EmployeeId,

                ServiceId = a.ServiceId,

                UserName = _context.Users
                    .Where(u => u.Id == a.UserId)
                    .Select(u => u.FirstName + " " + u.LastName)
                    .FirstOrDefault() ?? "",

                SalonName = _context.Salons
                    .Where(s => s.Id == a.SalonId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                EmployeeName = _context.Employees
                    .Where(e => e.Id == a.EmployeeId)
                    .Select(e => e.FirstName + " " + e.LastName)
                    .FirstOrDefault() ?? "",

                ServiceName = _context.Services
                    .Where(s => s.Id == a.ServiceId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                StartTime = a.StartTime,

                EndTime = a.EndTime,

                Status = a.Status,

                Price = a.Price,

                IsPaid = _context.Payments.Any(p =>
                    p.AppointmentId == a.Id && p.Status == PaymentStatuses.Completed),

                CreatedAt = a.CreatedAt,
                CancelledAt = a.CancelledAt,
                CancelledByUserId = a.CancelledByUserId,
                CancellationReason = a.CancellationReason
            })
            .OrderBy(a => a.StartTime)
            .ThenBy(a => a.Id)
            .ToPagedResultAsync(page, pageSize);
    }
    public async Task<PagedResult<AppointmentListDto>> GetMyForListAsync(
        int userId,
        int page,
        int pageSize,
        string? status)
    {
        var query = _context.Appointments
            .Where(a => a.UserId == userId);
        if (status == "Active")
        {
            query = query.Where(a =>
                a.Status == AppointmentStatuses.Pending ||
                a.Status == AppointmentStatuses.Confirmed);
        }
        else if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(a => a.Status == status);
        }

        return await query
            .Select(a => new AppointmentListDto
            {
                Id = a.Id,

                UserId = a.UserId,

                SalonId = a.SalonId,

                EmployeeId = a.EmployeeId,

                ServiceId = a.ServiceId,

                UserName = _context.Users
                    .Where(u => u.Id == a.UserId)
                    .Select(u => u.FirstName + " " + u.LastName)
                    .FirstOrDefault() ?? "",

                SalonName = _context.Salons
                    .Where(s => s.Id == a.SalonId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                EmployeeName = _context.Employees
                    .Where(e => e.Id == a.EmployeeId)
                    .Select(e => e.FirstName + " " + e.LastName)
                    .FirstOrDefault() ?? "",

                ServiceName = _context.Services
                    .Where(s => s.Id == a.ServiceId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                StartTime = a.StartTime,

                EndTime = a.EndTime,

                Status = a.Status,

                Price = a.Price,

                IsPaid = _context.Payments.Any(p =>
                    p.AppointmentId == a.Id && p.Status == PaymentStatuses.Completed),

                CreatedAt = a.CreatedAt,
                CancelledAt = a.CancelledAt,
                CancelledByUserId = a.CancelledByUserId,
                CancellationReason = a.CancellationReason
            })
            .OrderBy(a => a.StartTime)
            .ThenBy(a => a.Id)
            .ToPagedResultAsync(page, pageSize);
    }

    public async Task<AppointmentDto?> GetByIdAsync(int id)
    {
        return await _context.Appointments
            .Where(a => a.Id == id)
            .Select(a => new AppointmentDto
            {
                Id = a.Id,
                UserId = a.UserId,
                SalonId = a.SalonId,
                EmployeeId = a.EmployeeId,
                ServiceId = a.ServiceId,
                StartTime = a.StartTime,
                EndTime = a.EndTime,
                Status = a.Status,
                Price = a.Price,
                IsPaid = _context.Payments.Any(p =>
                    p.AppointmentId == a.Id && p.Status == PaymentStatuses.Completed),
                CreatedAt = a.CreatedAt,
                CancelledAt = a.CancelledAt,
                CancelledByUserId = a.CancelledByUserId,
                CancellationReason = a.CancellationReason
            })
            .FirstOrDefaultAsync();
    }

    public async Task<AppointmentDto> CreateAsync(
        AppointmentDto appointmentDto,
        int actorUserId)
    {
        // Provjera korisnika
        var userExists = await _context.Users
            .AnyAsync(x => x.Id == appointmentDto.UserId);

        if (!userExists)
            throw new BusinessException("Korisnik ne postoji.");

        // Provjera salona
        var salon = await _context.Salons
            .FirstOrDefaultAsync(x => x.Id == appointmentDto.SalonId);
        if (salon == null)
            throw new BusinessException("Salon ne postoji.");
        if (!salon.IsActive)
            throw new BusinessException("Odabrani salon nije aktivan i nije dostupan za rezervacije.");

        // Provjera zaposlenika
        var employee = await _context.Employees
            .FirstOrDefaultAsync(x => x.Id == appointmentDto.EmployeeId);

        if (employee == null)
            throw new BusinessException("Zaposlenik ne postoji.");
        if (!employee.IsActive)
            throw new BusinessException("Odabrani zaposlenik nije aktivan i nije dostupan za rezervacije.");

        // Zaposlenik mora pripadati salonu
        if (employee.SalonId != appointmentDto.SalonId)
            throw new BusinessException("Zaposlenik ne pripada odabranom salonu.");

        // Provjera usluge
        var service = await _context.Services
            .FirstOrDefaultAsync(x => x.Id == appointmentDto.ServiceId);

        if (service == null)
            throw new BusinessException("Usluga ne postoji.");
        if (!service.IsActive)
            throw new BusinessException("Odabrana usluga nije aktivna i nije dostupna za rezervacije.");

        // Usluga mora pripadati salonu
        if (service.SalonId != appointmentDto.SalonId)
            throw new BusinessException("Usluga ne pripada odabranom salonu.");

        // Provjera da zaposlenik pruža odabranu uslugu
        var employeeProvidesService =
            await _context.EmployeeServices.AnyAsync(es =>
                es.EmployeeId == appointmentDto.EmployeeId &&
                es.ServiceId == appointmentDto.ServiceId);

        if (!employeeProvidesService)
        {
            throw new BusinessException(
                "Odabrani zaposlenik ne pruža odabranu uslugu.");
        }

        // Računamo EndTime na osnovu trajanja usluge
        var startTime = appointmentDto.StartTime;

        var endTime = startTime.AddMinutes(
            service.DurationInMinutes);

        // Termin ne smije biti u prošlosti
        if (startTime <= DateTime.Now)
        {
            throw new BusinessException(
                "Termin ne može biti zakazan u prošlosti.");
        }

        var workingHours = await GetWorkingHoursAsync(
            employee.Id,
            startTime.Date);
        if (!IsWithinWorkingHours(workingHours, startTime, endTime))
            throw new BusinessException(
                "Zaposlenik ne radi tog dana ili termin nije unutar njegovog radnog vremena.");

        // Provjera preklapanja termina
        var overlappingAppointment =
            await _context.Appointments.AnyAsync(a =>
                a.EmployeeId == appointmentDto.EmployeeId &&
                a.Status != AppointmentStatuses.Cancelled &&
                a.StartTime < endTime &&
                a.EndTime > startTime);

        if (overlappingAppointment)
            throw new BusinessException(
                "Zaposlenik već ima termin u odabranom vremenu.");

        // Provjera preklapanja termina za istog korisnika
        var userOverlappingAppointment =
            await _context.Appointments.AnyAsync(a =>
                a.UserId == appointmentDto.UserId &&
                a.Status != AppointmentStatuses.Cancelled &&
                a.StartTime < endTime &&
                a.EndTime > startTime);

        if (userOverlappingAppointment)
            throw new BusinessException(
                "Korisnik već ima termin u odabranom vremenu.");

        // Kreiranje termina
        var appointment = new Appointment
        {
            UserId = appointmentDto.UserId,
            SalonId = appointmentDto.SalonId,
            EmployeeId = appointmentDto.EmployeeId,
            ServiceId = appointmentDto.ServiceId,
            StartTime = startTime,
            EndTime = endTime,
            Status = AppointmentStatuses.Pending,
            Price = service.Price,
            CreatedAt = DateTime.UtcNow
        };

        _context.Appointments.Add(appointment);
        _context.AppointmentStatusHistories.Add(new AppointmentStatusHistory
        {
            Appointment = appointment,
            PreviousStatus = null,
            NewStatus = appointment.Status,
            ChangedByUserId = actorUserId,
            ChangedAt = DateTime.UtcNow
        });

        // Prvo moramo sačuvati Appointment
        // kako bi SQL Server generisao njegov Id.
        await _context.SaveChangesAsync();

        // Tek sada appointment.Id postoji.
        var notification = new Notification
        {
            UserId = appointment.UserId,
            AppointmentId = appointment.Id,
            Title = "Termin uspješno rezervisan",
            Message =
                $"Vaš termin je uspješno rezervisan za {appointment.StartTime:dd.MM.yyyy. HH:mm}.",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);

        // Čuvamo automatski kreiranu notifikaciju
        await _context.SaveChangesAsync();

        return new AppointmentDto
        {
            Id = appointment.Id,
            UserId = appointment.UserId,
            SalonId = appointment.SalonId,
            EmployeeId = appointment.EmployeeId,
            ServiceId = appointment.ServiceId,
            StartTime = appointment.StartTime,
            EndTime = appointment.EndTime,
            Status = appointment.Status,
            Price = appointment.Price,
            CreatedAt = appointment.CreatedAt
        };
    }

    public async Task<bool> UpdateAsync(
    int id,
    AppointmentDto appointmentDto,
    int actorUserId)
    {
        var appointment = await _context.Appointments
            .FirstOrDefaultAsync(x => x.Id == id);

        if (appointment == null)
            return false;

        // Zapamtimo stari status
        var oldStatus = appointment.Status;

        // Provjera da li se mijenja raspored termina
        var scheduleChanged =
            appointment.StartTime != appointmentDto.StartTime ||
            appointment.SalonId != appointmentDto.SalonId ||
            appointment.EmployeeId != appointmentDto.EmployeeId ||
            appointment.ServiceId != appointmentDto.ServiceId;

        if (scheduleChanged)
        {
            var salonExists = await _context.Salons
                .AnyAsync(x => x.Id == appointmentDto.SalonId);
            if (!salonExists)
                throw new BusinessException("Salon ne postoji.");
            var salonIsActive = await _context.Salons
                .AnyAsync(x => x.Id == appointmentDto.SalonId && x.IsActive);
            if (!salonIsActive)
                throw new BusinessException(
                    "Odabrani salon nije aktivan i nije dostupan za rezervacije.");

            var service = await _context.Services
                .FirstOrDefaultAsync(x =>
                    x.Id == appointmentDto.ServiceId &&
                    x.SalonId == appointmentDto.SalonId);
            if (service == null)
                throw new BusinessException(
                    "Odabrana usluga ne postoji u odabranom salonu.");
            if (!service.IsActive)
                throw new BusinessException(
                    "Odabrana usluga nije aktivna i nije dostupna za rezervacije.");

            var employee = await _context.Employees
                .FirstOrDefaultAsync(x =>
                    x.Id == appointmentDto.EmployeeId &&
                    x.SalonId == appointmentDto.SalonId);
            if (employee == null)
                throw new BusinessException(
                    "Odabrani zaposlenik ne pripada odabranom salonu.");
            if (!employee.IsActive)
                throw new BusinessException(
                    "Odabrani zaposlenik nije aktivan i nije dostupan za rezervacije.");

            var employeeProvidesService =
                await _context.EmployeeServices.AnyAsync(es =>
                    es.EmployeeId == appointmentDto.EmployeeId &&
                    es.ServiceId == appointmentDto.ServiceId);
            if (!employeeProvidesService)
                throw new BusinessException(
                    "Odabrani zaposlenik ne pruža odabranu uslugu.");

            var startTime = appointmentDto.StartTime;
            var endTime = startTime.AddMinutes(service.DurationInMinutes);

            if (startTime <= DateTime.Now)
                throw new BusinessException(
                    "Termin ne može biti zakazan u prošlosti.");

            var workingHours = await GetWorkingHoursAsync(
                employee.Id,
                startTime.Date);
            if (!IsWithinWorkingHours(workingHours, startTime, endTime))
                throw new BusinessException(
                    "Zaposlenik ne radi tog dana ili termin nije unutar njegovog radnog vremena.");

            var employeeOverlaps = await _context.Appointments.AnyAsync(a =>
                a.Id != id &&
                a.EmployeeId == appointmentDto.EmployeeId &&
                a.Status != AppointmentStatuses.Cancelled &&
                a.StartTime < endTime &&
                a.EndTime > startTime);
            if (employeeOverlaps)
                throw new BusinessException(
                    "Zaposlenik već ima termin u odabranom vremenu.");

            var userOverlaps = await _context.Appointments.AnyAsync(a =>
                a.Id != id &&
                a.UserId == appointment.UserId &&
                a.Status != AppointmentStatuses.Cancelled &&
                a.StartTime < endTime &&
                a.EndTime > startTime);
            if (userOverlaps)
                throw new BusinessException(
                    "Korisnik već ima termin u odabranom vremenu.");

            appointment.SalonId = appointmentDto.SalonId;
            appointment.ServiceId = appointmentDto.ServiceId;
            appointment.EmployeeId = appointmentDto.EmployeeId;
            appointment.StartTime = startTime;
            appointment.EndTime = endTime;
            appointment.Price = service.Price;
        }

        if (!string.IsNullOrWhiteSpace(appointmentDto.Status))
        {
            var newStatus = appointmentDto.Status;

            if (!AppointmentStatuses.IsKnown(newStatus))
            {
                throw new BusinessException(
                    "Neispravan status termina.");
            }

            if (oldStatus == AppointmentStatuses.Completed)
            {
                throw new BusinessException(
                    "Završen termin nije moguće mijenjati.");
            }

            if (oldStatus == AppointmentStatuses.Cancelled)
            {
                throw new BusinessException(
                    "Otkazan termin nije moguće mijenjati.");
            }

            if (oldStatus != newStatus &&
                !AppointmentStateMachine.CanTransition(oldStatus, newStatus))
            {
                throw new BusinessException(
                    $"Nije dozvoljen prelaz statusa '{oldStatus}' u '{newStatus}'.");
            }

            if (newStatus == AppointmentStatuses.Confirmed &&
                oldStatus != AppointmentStatuses.Confirmed)
            {
                throw new BusinessException(
                    "Termin može potvrditi samo uspješno završeno plaćanje.");
            }

            if (newStatus == AppointmentStatuses.Cancelled &&
                oldStatus != AppointmentStatuses.Cancelled)
            {
                throw new BusinessException(
                    "Termin otkažite posebnom operacijom uz razlog otkazivanja.");
            }

            if (newStatus == AppointmentStatuses.Completed &&
                appointment.EndTime > DateTime.Now)
            {
                throw new BusinessException(
                    "Termin se ne može označiti kao završen prije njegovog završetka.");
            }

            appointment.Status = newStatus;
        }

        // Ako se status promijenio,
        // kreiramo automatsku notifikaciju.
        if (oldStatus != appointment.Status)
        {
            _context.AppointmentStatusHistories.Add(
                new AppointmentStatusHistory
                {
                    AppointmentId = appointment.Id,
                    PreviousStatus = oldStatus,
                    NewStatus = appointment.Status,
                    ChangedByUserId = actorUserId,
                    ChangedAt = DateTime.UtcNow
                });

            string? title = null;
            string? message = null;

            if (appointment.Status == AppointmentStatuses.Confirmed)
            {
                title = "Termin potvrđen";

                message =
                    $"Vaš termin je potvrđen za " +
                    $"{appointment.StartTime:dd.MM.yyyy. HH:mm}.";
            }
            else if (appointment.Status == AppointmentStatuses.Cancelled)
            {
                title = "Termin otkazan";

                message =
                    $"Vaš termin za " +
                    $"{appointment.StartTime:dd.MM.yyyy. HH:mm} je otkazan.";
            }

            if (title != null && message != null)
            {
                var notification = new Notification
                {
                    UserId = appointment.UserId,
                    AppointmentId = appointment.Id,
                    Title = title,
                    Message = message,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Notifications.Add(notification);
            }
        }

        if (scheduleChanged)
        {
            _context.Notifications.Add(new Notification
            {
                UserId = appointment.UserId,
                AppointmentId = appointment.Id,
                Type = "AppointmentUpdated",
                Title = "Termin izmijenjen",
                Message =
                    $"Termin je izmijenjen. Novi termin je " +
                    $"{appointment.StartTime:dd.MM.yyyy. HH:mm}.",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> CancelAsync(
        int id,
        int actorUserId,
        string reason,
        bool isAdmin)
    {
        var appointment = await _context.Appointments
            .FirstOrDefaultAsync(x => x.Id == id &&
                (isAdmin || x.UserId == actorUserId));

        if (appointment == null)
            return false;

        if (appointment.Status == AppointmentStatuses.Cancelled)
            throw new BusinessException("Termin je već otkazan.");

        var isPaid = await _context.Payments.AnyAsync(payment =>
            payment.AppointmentId == id &&
            payment.Status == PaymentStatuses.Completed);
        if (isPaid)
            throw new BusinessException(
                "Termin je već plaćen i ne može se otkazati kroz ovaj tok.");

        if (!AppointmentStateMachine.CanTransition(
                appointment.Status,
                AppointmentStatuses.Cancelled))
        {
            throw new BusinessException(
                "Moguće je otkazati samo aktivan termin.");
        }

        var previousStatus = appointment.Status;
        appointment.Status = AppointmentStatuses.Cancelled;
        appointment.CancelledAt = DateTime.UtcNow;
        appointment.CancelledByUserId = actorUserId;
        appointment.CancellationReason = reason.Trim();
        _context.AppointmentStatusHistories.Add(
            new AppointmentStatusHistory
            {
                AppointmentId = appointment.Id,
                PreviousStatus = previousStatus,
                NewStatus = AppointmentStatuses.Cancelled,
                ChangedByUserId = actorUserId,
                ChangedAt = appointment.CancelledAt.Value
            });
        _context.Notifications.Add(new Notification
        {
            UserId = appointment.UserId,
            AppointmentId = appointment.Id,
            Type = "AppointmentCancelled",
            Title = "Termin otkazan",
            Message =
                $"Vaš termin za {appointment.StartTime:dd.MM.yyyy. HH:mm} je otkazan. Razlog: {reason.Trim()}",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<List<AppointmentStatusHistoryDto>> GetStatusHistoryAsync(
        int appointmentId)
    {
        return await _context.AppointmentStatusHistories
            .Where(history => history.AppointmentId == appointmentId)
            .OrderBy(history => history.ChangedAt)
            .Select(history => new AppointmentStatusHistoryDto
            {
                Id = history.Id,
                PreviousStatus = history.PreviousStatus,
                NewStatus = history.NewStatus,
                ChangedByUserId = history.ChangedByUserId,
                ChangedByName = _context.Users
                    .Where(user => user.Id == history.ChangedByUserId)
                    .Select(user => user.FirstName + " " + user.LastName)
                    .FirstOrDefault() ?? string.Empty,
                ChangedAt = history.ChangedAt
            })
            .ToListAsync();
    }

    public async Task<List<AvailableSlotDto>> GetAvailableSlotsAsync(
    int salonId,
    int employeeId,
    int serviceId,
    DateTime date)
    {
        // Provjera zaposlenika
        var employee = await _context.Employees
            .FirstOrDefaultAsync(x =>
                x.Id == employeeId &&
                x.SalonId == salonId &&
                x.IsActive);

        if (employee == null)
            throw new BusinessException(
                "Zaposlenik ne postoji ili ne pripada odabranom salonu.");

        // Provjera usluge
        var service = await _context.Services
            .FirstOrDefaultAsync(x =>
                x.Id == serviceId &&
                x.SalonId == salonId &&
                x.IsActive);

        if (service == null)
            throw new BusinessException(
                "Usluga ne postoji ili ne pripada odabranom salonu.");

        var workingHours = await GetWorkingHoursAsync(employee.Id, date.Date);
        if (workingHours == null)
            return new List<AvailableSlotDto>();

        var dayStart = date.Date.Add(workingHours.StartTime);
        var dayEnd = date.Date.Add(workingHours.EndTime);

        // Uzimamo postojeće aktivne termine tog zaposlenika za taj dan
        var appointments = await _context.Appointments
            .Where(x =>
                x.EmployeeId == employeeId &&
                x.StartTime.Date == date.Date &&
                x.Status != AppointmentStatuses.Cancelled)
            .OrderBy(x => x.StartTime)
            .ToListAsync();

        var availableSlots = new List<AvailableSlotDto>();

        var currentStart = dayStart;

        if (date.Date == DateTime.Today)
        {
            var now = DateTime.Now;

            if (now > currentStart)
            {
                var minutesFromMidnight =
                    now.Hour * 60 + now.Minute;

                var nextSlotMinutes =
                    ((minutesFromMidnight + 29) / 30) * 30;

                currentStart = date.Date.AddMinutes(
                    nextSlotMinutes);
            }
        }

        while (currentStart.AddMinutes(service.DurationInMinutes) <= dayEnd)
        {
            var currentEnd =
                currentStart.AddMinutes(service.DurationInMinutes);

            var overlaps = appointments.Any(a =>
                a.StartTime < currentEnd &&
                a.EndTime > currentStart);

            availableSlots.Add(new AvailableSlotDto
            {
                StartTime = currentStart,
                EndTime = currentEnd,
                IsAvailable =
                    IsWithinWorkingHours(
                        workingHours,
                        currentStart,
                        currentEnd) &&
                    !overlaps
            });

            currentStart = currentStart.AddMinutes(30);
        }

        return availableSlots;
    }

    public async Task<List<DashboardAppointmentDto>> GetDashboardAppointmentsAsync(
    DateTime date,
    int? salonId)
    {
        var query = _context.Appointments
            .Where(a =>
                a.StartTime.Date == date.Date &&
                a.Status != AppointmentStatuses.Cancelled);

        if (salonId.HasValue)
        {
            query = query.Where(a =>
                a.SalonId == salonId.Value);
        }

        return await (
            from appointment in query
            join user in _context.Users.AsNoTracking()
                on appointment.UserId equals user.Id
            join salon in _context.Salons.AsNoTracking()
                on appointment.SalonId equals salon.Id
            join service in _context.Services.AsNoTracking()
                on appointment.ServiceId equals service.Id
            orderby appointment.StartTime
            select new DashboardAppointmentDto
            {
                Id = appointment.Id,
                UserName = user.FirstName + " " + user.LastName,
                SalonName = salon.Name,
                ServiceName = service.Name,
                StartTime = appointment.StartTime,
                EndTime = appointment.EndTime,
                Status = appointment.Status,
                Price = appointment.Price
            })
            .ToListAsync();
    }

    public async Task<DashboardAvailableSlotsDto> GetDashboardAvailableSlotsAsync(
    DateTime date,
    int? salonId)
    {
        var employeesQuery = _context.Employees
            .Where(x => x.IsActive);

        if (salonId.HasValue)
        {
            employeesQuery = employeesQuery
                .Where(x => x.SalonId == salonId.Value);
        }

        var activeEmployees = await employeesQuery.ToListAsync();

        var activeServices = await _context.Services
            .Where(x => x.IsActive)
            .ToListAsync();

        var appointmentsQuery = _context.Appointments
            .Where(x =>
                x.StartTime.Date == date.Date &&
                x.Status != AppointmentStatuses.Cancelled);

        if (salonId.HasValue)
        {
            appointmentsQuery = appointmentsQuery
                .Where(x => x.SalonId == salonId.Value);
        }

        var appointments = await appointmentsQuery.ToListAsync();

        int totalSlots = 0;
        int occupiedSlots = 0;

        foreach (var employee in activeEmployees)
        {
            var workingHours = await GetWorkingHoursAsync(
                employee.Id,
                date.Date);
            if (workingHours == null)
                continue;

            var dayStart = date.Date.Add(workingHours.StartTime);
            var dayEnd = date.Date.Add(workingHours.EndTime);

            var employeeServices = activeServices
                .Where(x => x.SalonId == employee.SalonId)
                .ToList();

            if (!employeeServices.Any())
                continue;

            var currentStart = dayStart;

            while (currentStart.AddMinutes(30) <= dayEnd)
            {
                if (IsWithinWorkingHours(
                        workingHours,
                        currentStart,
                        currentStart.AddMinutes(30)))
                    totalSlots++;
                currentStart = currentStart.AddMinutes(30);
            }

            var employeeAppointments = appointments
                .Where(x => x.EmployeeId == employee.Id)
                .ToList();

            foreach (var appointment in employeeAppointments)
            {
                var durationSlots = Math.Max(
                    1,
                    (int)Math.Ceiling(
                        (appointment.EndTime - appointment.StartTime)
                            .TotalMinutes / 30));

                occupiedSlots += durationSlots;
            }
        }

        occupiedSlots = Math.Min(
            occupiedSlots,
            totalSlots);

        var availableSlots = Math.Max(
            0,
            totalSlots - occupiedSlots);

        var percentage = totalSlots == 0
            ? 0
            : (int)Math.Round(
                availableSlots * 100.0 / totalSlots);

        return new DashboardAvailableSlotsDto
        {
            AvailableSlots = availableSlots,
            TotalSlots = totalSlots,
            OccupiedSlots = occupiedSlots,
            Percentage = percentage
        };
    }

    private Task<EmployeeWorkingHour?> GetWorkingHoursAsync(
        int employeeId,
        DateTime date)
    {
        return _context.EmployeeWorkingHours.FirstOrDefaultAsync(hours =>
            hours.EmployeeId == employeeId &&
            hours.DayOfWeek == date.DayOfWeek);
    }

    private static bool IsWithinWorkingHours(
        EmployeeWorkingHour? workingHours,
        DateTime startTime,
        DateTime endTime)
    {
        if (workingHours == null || startTime.Date != endTime.Date)
            return false;

        var workStart = startTime.Date.Add(workingHours.StartTime);
        var workEnd = startTime.Date.Add(workingHours.EndTime);
        return startTime >= workStart && endTime <= workEnd && endTime > startTime;
    }
}
