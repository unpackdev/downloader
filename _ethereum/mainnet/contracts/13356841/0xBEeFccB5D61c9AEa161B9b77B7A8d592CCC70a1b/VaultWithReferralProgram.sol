pragma solidity ^0.6.0;

import "./IReferralProgram.sol";

/// @title WithReferalProgramVault
/// @notice Vault for consumers of the system
abstract contract VaultWithReferralProgram {
    /// @notice The referral program
    IReferralProgram public referralProgram;
    address public treasury;

    function _configureVaultWithReferralProgram(
        address _referralProgram,
        address _treasury
    ) internal {
        referralProgram = IReferralProgram(_referralProgram);
        treasury = _treasury;
    }

    function _registerUserInReferralProgramIfNeeded(address _user) internal {
        (bool _userExists, ) = referralProgram.users(_user);
        if (!_userExists) {
            referralProgram.registerUser(treasury, _user);
        }
    }
}
