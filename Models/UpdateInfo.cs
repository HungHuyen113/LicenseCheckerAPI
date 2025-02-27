<<<<<<< HEAD
<<<<<<< HEAD
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
=======
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class UpdateInfo
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string UpdateAvailable { get; set; }  // "yes" hoặc "no"

    [Required]
    public string DownloadLink { get; set; }

    [Required]
    public string UpdateMessage { get; set; }

    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
>>>>>>> 1dcc1d58c927d370e9136a7d0e67659fdbc5c2e1
=======
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

public class UpdateInfo
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string UpdateAvailable { get; set; }  // "yes" hoặc "no"

    [Required]
    public string DownloadLink { get; set; }

    [Required]
    public string UpdateMessage { get; set; }

    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
>>>>>>> 1dcc1d58c927d370e9136a7d0e67659fdbc5c2e1
