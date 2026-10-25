using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IEmployeeService
{
    Task<PagedResult<EmployeeDto>> GetAllAsync(int page, int pageSize);

    Task<EmployeeDto?> GetByIdAsync(int id);

    Task<EmployeeDto> CreateAsync(EmployeeDto employeeDto);

    Task<bool> UpdateAsync(int id, EmployeeDto employeeDto);

    Task<bool> DeleteAsync(int id);
}