using FluentValidation;
using LeafGo.Application.DTOs.Auth;

namespace LeafGo.Application.Validators
{
    public class SocialLoginRequestValidator : AbstractValidator<SocialLoginRequest>
    {
        public SocialLoginRequestValidator()
        {
            RuleFor(x => x.Provider)
                .NotEmpty().WithMessage("Provider is required")
                .Must(p => p == "Google" || p == "Facebook")
                .WithMessage("Provider must be Google or Facebook");

            RuleFor(x => x.Token)
                .NotEmpty().WithMessage("Token is required");
        }
    }
}
