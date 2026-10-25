using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface ICityService
{
    Task<List<CityDto>> GetAllAsync();

    Task<CityDto?> GetByIdAsync(int id);

    Task<CityDto> CreateAsync(CityDto cityDto);

    Task<bool> UpdateAsync(int id, CityDto cityDto);

    Task<bool> DeleteAsync(int id);
}
