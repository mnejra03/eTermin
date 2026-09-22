using eTermin.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Data;

public class eTerminDbContext : DbContext
{
    public eTerminDbContext(DbContextOptions<eTerminDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Salon> Salons { get; set; }
    public DbSet<Employee> Employees { get; set; }
    public DbSet<Service> Services { get; set; }
    public DbSet<EmployeeService> EmployeeServices { get; set; }
    public DbSet<Appointment> Appointments { get; set; }
    public DbSet<Payment> Payments { get; set; }
    public DbSet<Notification> Notifications { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Decimal precision
        modelBuilder.Entity<Service>()
            .Property(x => x.Price)
            .HasPrecision(18, 2);

        modelBuilder.Entity<Appointment>()
            .Property(x => x.Price)
            .HasPrecision(18, 2);

        modelBuilder.Entity<Payment>()
            .Property(x => x.Amount)
            .HasPrecision(18, 2);

        // Salon -> Employees
        modelBuilder.Entity<Employee>()
            .HasOne<Salon>()
            .WithMany()
            .HasForeignKey(x => x.SalonId)
            .OnDelete(DeleteBehavior.Restrict);

        // Salon -> Services
        modelBuilder.Entity<Service>()
            .HasOne<Salon>()
            .WithMany()
            .HasForeignKey(x => x.SalonId)
            .OnDelete(DeleteBehavior.Restrict);

        // Employee -> Services
        modelBuilder.Entity<EmployeeService>()
            .HasKey(x => new
            {
                x.EmployeeId,
                x.ServiceId
            });

        modelBuilder.Entity<EmployeeService>()
            .HasOne(x => x.Employee)
            .WithMany(x => x.EmployeeServices)
            .HasForeignKey(x => x.EmployeeId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<EmployeeService>()
            .HasOne(x => x.Service)
            .WithMany(x => x.EmployeeServices)
            .HasForeignKey(x => x.ServiceId)
            .OnDelete(DeleteBehavior.Cascade);

        // Appointment -> User
        modelBuilder.Entity<Appointment>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Appointment -> Salon
        modelBuilder.Entity<Appointment>()
            .HasOne<Salon>()
            .WithMany()
            .HasForeignKey(x => x.SalonId)
            .OnDelete(DeleteBehavior.Restrict);

        // Appointment -> Employee
        modelBuilder.Entity<Appointment>()
            .HasOne<Employee>()
            .WithMany()
            .HasForeignKey(x => x.EmployeeId)
            .OnDelete(DeleteBehavior.Restrict);

        // Appointment -> Service
        modelBuilder.Entity<Appointment>()
            .HasOne<Service>()
            .WithMany()
            .HasForeignKey(x => x.ServiceId)
            .OnDelete(DeleteBehavior.Restrict);

        // Payment -> Appointment
        modelBuilder.Entity<Payment>()
            .HasOne<Appointment>()
            .WithMany()
            .HasForeignKey(x => x.AppointmentId)
            .OnDelete(DeleteBehavior.Cascade);

        // Notification -> User
        modelBuilder.Entity<Notification>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Notification -> Appointment
        modelBuilder.Entity<Notification>()
            .HasOne<Appointment>()
            .WithMany()
            .HasForeignKey(x => x.AppointmentId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}