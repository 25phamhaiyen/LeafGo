using FluentValidation;
using LeafGo.Application.DTOs.Auth;

namespace LeafGo.Application.Validators
{
    public class CompleteSocialRegistrationRequestValidator : AbstractValidator<CompleteSocialRegistrationRequest>
    {
        public CompleteSocialRegistrationRequestValidator()
        {
            RuleFor(x => x.Provider)
                .NotEmpty().WithMessage("Provider is required")
                .Must(p => p == "Google" || p == "Facebook")
                .WithMessage("Provider must be Google or Facebook");

            RuleFor(x => x.Token)
                .NotEmpty().WithMessage("Token is required");

            RuleFor(x => x.Role)
                .NotEmpty().WithMessage("Role is required")
                .Must(r => r == "User" || r == "Driver")
                .WithMessage("Role must be User or Driver");

            RuleFor(x => x.PhoneNumber)
                .NotEmpty().WithMessage("Phone number is required")
                .Matches(@"^(0|\+84)[0-9]{9,10}$")
                .WithMessage("Phone number must be a valid Vietnamese phone number");
        }
    }
}
