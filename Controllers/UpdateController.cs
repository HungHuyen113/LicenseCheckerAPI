using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

[ApiController]
[Route("api/update")]
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
            // ✅ Nếu không có dữ liệu, trả về dữ liệu mặc định
            return Ok(new UpdateInfo
            {
                UpdateAvailable = "no",
                DownloadLink = "",
                UpdateMessage = "Không có bản cập nhật nào.",
                CreatedAt = DateTime.UtcNow
            });
        }

        return Ok(updateInfo);
    }

    [HttpPost]
    public async Task<IActionResult> SetUpdateInfo([FromBody] UpdateInfo update)
    {
        if (update == null || string.IsNullOrWhiteSpace(update.UpdateAvailable))
        {
            return BadRequest("Dữ liệu không hợp lệ.");
        }

        _context.UpdateInfo.Add(update);
        await _context.SaveChangesAsync();

        return Ok("Thông tin cập nhật đã được lưu.");
    }
}
