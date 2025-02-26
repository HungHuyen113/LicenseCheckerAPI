using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;
[Route("api/license")]
[ApiController]
public class LicenseController : ControllerBase
{
    private readonly LicenseDbContext _context;

    public LicenseController(LicenseDbContext context)
    {
        _context = context;
    }

    [HttpPost("check")]
    public async Task<IActionResult> CheckLicense([FromBody] License licenseRequest)
    {
        var license = await _context.Licenses.FirstOrDefaultAsync(l =>
            l.LicenseKey == licenseRequest.LicenseKey &&
            l.MachineId == licenseRequest.MachineId &&
            l.IsActive);

        if (license == null)
            return Unauthorized("License không hợp lệ!");

        return Ok("License hợp lệ!");
    }
// API để đăng ký license mới
    [HttpPost("register")]
    public async Task<IActionResult> RegisterLicense([FromBody] License newLicense)
    {
        if (string.IsNullOrWhiteSpace(newLicense.LicenseKey) || string.IsNullOrWhiteSpace(newLicense.MachineId))
        {
            return BadRequest("LicenseKey và MachineId không được để trống.");
        }

        var existingLicense = await _context.Licenses.FirstOrDefaultAsync(l =>
            l.LicenseKey == newLicense.LicenseKey && l.MachineId == newLicense.MachineId);

        if (existingLicense != null)
        {
            return Conflict("License đã tồn tại.");
        }

        newLicense.IsActive = true; // Mặc định license mới là hợp lệ
        _context.Licenses.Add(newLicense);
        await _context.SaveChangesAsync();

        return Ok("License đã được đăng ký thành công!");
    }
}
