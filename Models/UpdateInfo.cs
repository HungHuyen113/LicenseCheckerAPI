using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class UpdateInfo
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string UpdateAvailable { get; set; } = "no";  // ✅ Giá trị mặc định

    [Required]
    public string DownloadLink { get; set; } = "";  // ✅ Tránh lỗi null

    [Required]
    public string UpdateMessage { get; set; } = "Không có bản cập nhật nào.";  // ✅ Giá trị mặc định

    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
