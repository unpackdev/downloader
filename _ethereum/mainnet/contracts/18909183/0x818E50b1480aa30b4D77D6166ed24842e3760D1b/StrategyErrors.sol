// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @title Dollet StrategyErrors library
 * @author Dollet Team
 * @notice Library with all Strategy errors.
 */
library StrategyErrors {
    error InsufficientWithdrawalTokenOut();
    error InsufficientDepositTokenOut();
    error SlippageToleranceTooHigh();
    error NotVault(address _caller);
    error ETHTransferError();
    error WrongStuckToken();
    error LengthsMismatch();
    error UseWantToken();
}
