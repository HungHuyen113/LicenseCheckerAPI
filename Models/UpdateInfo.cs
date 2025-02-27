using System;
using System.ComponentModel.DataAnnotations;

public class UpdateInfo
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string UpdateAvailable { get; set; } = "no";

    [Required]
    public string DownloadLink { get; set; } = "";

    [Required]
    public string UpdateMessage { get; set; } = "Không có bản cập nhật nào.";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
