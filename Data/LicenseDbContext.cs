using Microsoft.EntityFrameworkCore;

public class LicenseDbContext : DbContext
{
    public LicenseDbContext(DbContextOptions<LicenseDbContext> options) : base(options) { }

    public DbSet<License> Licenses { get; set; }
    public DbSet<UpdateInfo> UpdateInfo { get; set; }  // 🔹 Thêm dòng này
}
