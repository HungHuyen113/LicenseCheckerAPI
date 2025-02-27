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
    // 🔹 API XÓA LICENSE (Dùng `POST` Thay Vì `DELETE`)
    [HttpPost("delete")]
    public async Task<IActionResult> DeleteLicense([FromBody] LicenseRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.LicenseKey) || string.IsNullOrWhiteSpace(request.MachineId))
        {
            return BadRequest(new { message = "Invalid request format." });
        }

        var license = await _context.Licenses.FirstOrDefaultAsync(l =>
            l.LicenseKey == request.LicenseKey && l.MachineId == request.MachineId);

        if (license == null)
        {
            return NotFound(new { message = "License not found." });
        }

        _context.Licenses.Remove(license);
        await _context.SaveChangesAsync();

        return Ok(new { message = "License deleted successfully!" });
    }



[HttpGet("list")]
public IActionResult GetLicenses()
{
    var licenses = _context.Licenses.ToList();
    return Ok(licenses);
}

}
