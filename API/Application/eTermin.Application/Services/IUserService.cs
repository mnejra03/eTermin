using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IUserService
{
    Task<List<UserDto>> GetAllAsync();

    Task<UserDto?> GetByIdAsync(int id);

    Task<bool> UpdateAsync(int id, UserDto userDto);

    Task<bool> DeleteAsync(int id);
}
