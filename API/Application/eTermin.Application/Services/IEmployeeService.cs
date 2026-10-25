using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IEmployeeService
{
    Task<List<EmployeeDto>> GetAllAsync();

    Task<EmployeeDto?> GetByIdAsync(int id);

    Task<EmployeeDto> CreateAsync(EmployeeDto employeeDto);

    Task<bool> UpdateAsync(int id, EmployeeDto employeeDto);

    Task<bool> DeleteAsync(int id);
}