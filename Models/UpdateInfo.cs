using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class UpdateInfo
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string? UpdateAvailable { get; set; }  // "yes" hoặc "no"

    [Required]
    public string? DownloadLink { get; set; }

    [Required]
    public string? UpdateMessage { get; set; }

    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
