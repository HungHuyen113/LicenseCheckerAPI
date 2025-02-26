public class License
{
    public int Id { get; set; }
    public string LicenseKey { get; set; } = string.Empty;  // Fix cảnh báo
    public string MachineId { get; set; } = string.Empty;  // Fix cảnh báo
    public bool IsActive { get; set; }
}
