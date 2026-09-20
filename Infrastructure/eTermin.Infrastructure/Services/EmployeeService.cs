using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class EmployeeService : IEmployeeService
{
    private readonly eTerminDbContext _context;

    public EmployeeService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<List<EmployeeDto>> GetAllAsync()
    {
        return await _context.Employees
            .Select(e => new EmployeeDto
            {
                Id = e.Id,
                SalonId = e.SalonId,
                FirstName = e.FirstName,
                LastName = e.LastName,
                Email = e.Email,
                PhoneNumber = e.PhoneNumber,
                Position = e.Position,
                WorkingHours = e.WorkingHours,
                IsActive = e.IsActive
            })
            .ToListAsync();
    }

    public async Task<EmployeeDto?> GetByIdAsync(int id)
    {
        return await _context.Employees
            .Where(e => e.Id == id)
            .Select(e => new EmployeeDto
            {
                Id = e.Id,
                SalonId = e.SalonId,
                FirstName = e.FirstName,
                LastName = e.LastName,
                Email = e.Email,
                PhoneNumber = e.PhoneNumber,
                Position = e.Position,
                WorkingHours = e.WorkingHours,
                IsActive = e.IsActive
            })
            .FirstOrDefaultAsync();
    }

    public async Task<EmployeeDto> CreateAsync(EmployeeDto employeeDto)
    {
        var employee = new Employee
        {
            SalonId = employeeDto.SalonId,
            FirstName = employeeDto.FirstName,
            LastName = employeeDto.LastName,
            Email = employeeDto.Email,
            PhoneNumber = employeeDto.PhoneNumber,
            Position = employeeDto.Position,
            WorkingHours = employeeDto.WorkingHours,
            IsActive = true
        };

        _context.Employees.Add(employee);

        await _context.SaveChangesAsync();

        return new EmployeeDto
        {
            Id = employee.Id,
            SalonId = employee.SalonId,
            FirstName = employee.FirstName,
            LastName = employee.LastName,
            Email = employee.Email,
            PhoneNumber = employee.PhoneNumber,
            Position = employee.Position,
            WorkingHours = employee.WorkingHours,
            IsActive = employee.IsActive
        };
    }

    public async Task<bool> UpdateAsync(int id, EmployeeDto employeeDto)
    {
        var employee = await _context.Employees.FindAsync(id);

        if (employee == null)
        {
            return false;
        }

        employee.SalonId = employeeDto.SalonId;
        employee.FirstName = employeeDto.FirstName;
        employee.LastName = employeeDto.LastName;
        employee.Email = employeeDto.Email;
        employee.PhoneNumber = employeeDto.PhoneNumber;
        employee.Position = employeeDto.Position;
        employee.WorkingHours = employeeDto.WorkingHours;
        employee.IsActive = employeeDto.IsActive;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var employee = await _context.Employees.FindAsync(id);

        if (employee == null)
        {
            return false;
        }

        _context.Employees.Remove(employee);

        await _context.SaveChangesAsync();

        return true;
    }
}