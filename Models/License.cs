using System.ComponentModel.DataAnnotations;

public class License
{
    [Key]
    public int Id { get; set; }

    [Required]
    public string LicenseKey { get; set; } = string.Empty;

    [Required]
    public string MachineId { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;
}
