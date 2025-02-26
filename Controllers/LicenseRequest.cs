using System.ComponentModel.DataAnnotations;

public class LicenseRequest
{
    [Required]
    public string LicenseKey { get; set; } = string.Empty;

    [Required]
    public string MachineId { get; set; } = string.Empty;
}

