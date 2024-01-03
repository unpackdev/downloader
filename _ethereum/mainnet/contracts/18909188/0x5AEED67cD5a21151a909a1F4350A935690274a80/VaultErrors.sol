// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IVault.sol";

/**
 * @title Dollet VaultErrors library
 * @author Dollet Team
 * @notice Library with all Vault errors.
 */
library VaultErrors {
    error TokenWontChange(IVault.TokenType _tokenType, address _token);
    error ErrorWithNativeTokenTransfer(address _to, uint256 _amount);
    error InvalidDepositAmount(address _token, uint256 _amount);
    error MustKeepOneToken(IVault.TokenType _tokenType);
    error NotAllowedWithdrawalToken(address _token);
    error NotAllowedDepositToken(address _token);
    error WrongWithdrawalAllowedTokensCount();
    error WrongDepositAllowedTokensCount();
    error DuplicateDepositAllowedToken();
    error DuplicateWithdrawalAllowedToken();
    error WithdrawStuckWrongToken();
    error ValueAndAmountMismatch();
    error WantToWithdrawTooHigh();
    error ZeroMinDepositAmount();
    error InsufficientAmount();
    error InvalidTokenStatus();
}
