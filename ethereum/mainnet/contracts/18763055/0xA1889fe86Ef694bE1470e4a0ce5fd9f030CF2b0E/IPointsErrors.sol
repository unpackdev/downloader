// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsErrors
 * @notice Interface for the errors thrown by the Points contract.
 */
interface IPointsErrors {
    /**
     * @notice Thrown when attempting to set rates while rates parameter and tokens parameter have different lengths.
     */
    error TokenRatesLengthsMismatched(uint256 tokensLength, uint256 ratesLength);
    /**
     * @notice Thrown when attempting to withdraw more of the token than has been deposited.
     */
    error InsufficientTokenBalance(uint256 tokenBalance, uint256 amount);
    /**
     * @notice Thrown when attempting to transfer when paused and not whitelisted.
     */
    error TransfersPaused();
    /**
     * @notice Thrown when attempting to deposit an unsupported token.
     */
    error TokenNotSupported(address token);
    /**
     * @notice Thrown when attempting to set multipliers with threshold and additionalRate arrays of different lengths.
     */
    error MultiplierLengthsMismatched(uint256 thresholdsLength, uint256 additionalRatesLength);
}
