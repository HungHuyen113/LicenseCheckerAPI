using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

[Route("api/update")]
[ApiController]
public class UpdateController : ControllerBase
{
    private readonly LicenseDbContext _context;

    public UpdateController(LicenseDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetUpdateInfo()
    {
        var updateInfo = await _context.UpdateInfo.OrderByDescending(u => u.CreatedAt).FirstOrDefaultAsync();
        if (updateInfo == null)
        {
            return NotFound(new { message = "Không có thông tin cập nhật nào." });
        }

        return Ok(updateInfo);
    }
}
