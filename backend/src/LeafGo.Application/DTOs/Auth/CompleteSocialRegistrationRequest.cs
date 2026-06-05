using System.ComponentModel.DataAnnotations;

namespace LeafGo.Application.DTOs.Auth
{
    public class CompleteSocialRegistrationRequest
    {
        [Required(ErrorMessage = "Provider is required")]
        [RegularExpression("^(Google|Facebook)$", ErrorMessage = "Provider must be Google or Facebook")]
        public string Provider { get; set; } = string.Empty;

        [Required(ErrorMessage = "Token is required")]
        public string Token { get; set; } = string.Empty;

        [Required(ErrorMessage = "Role is required")]
        [RegularExpression("^(User|Driver)$", ErrorMessage = "Role must be User or Driver")]
        public string Role { get; set; } = string.Empty;

        [Required(ErrorMessage = "Phone number is required")]
        [Phone(ErrorMessage = "Invalid phone number format")]
        public string PhoneNumber { get; set; } = string.Empty;
    }
}
