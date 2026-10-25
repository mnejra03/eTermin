using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IServiceService
{
    Task<PagedResult<ServiceDto>> GetAllAsync(int page, int pageSize);

    Task<ServiceDto?> GetByIdAsync(int id);

    Task<ServiceDto> CreateAsync(ServiceDto serviceDto);

    Task<bool> UpdateAsync(int id, ServiceDto serviceDto);

    Task<bool> DeleteAsync(int id);
}