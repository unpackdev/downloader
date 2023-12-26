// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

/**
 * @title IPointsErrors
 * @notice Interface for the errors thrown by the Points contract.
 */
interface IPointsErrors {
    /**
     * @notice Thrown when attempting to set rates while rates parameter and tokens parameter have different lengths.
     * @param tokensLength The length of the tokens array
     * @param ratesLength The length of the rates array
     */
    error TokenRatesLengthsMismatched(uint256 tokensLength, uint256 ratesLength);
    /**
     * @notice Thrown when attempting to transfer when paused and not whitelisted.
     */
    error TransfersPaused();

    /**
     * @notice Thrown when attempting to burn tokens without being the authorized burner.
     * @param account The account attempting to burn tokens
     */
    error UnauthorizedBurner(address account);

    /**
     * @notice Thrown when attempting to stake an unsupported token.
     * @param token The token that was not supported
     */
    error TokenNotSupported(address token);
    /**
     * @notice Thrown when attempting to unstake more of the token than has been staked.
     * @param tokenBalance The amount of tokens the user had deposited into the contract
     * @param amount The amount of tokens the user was attempting to withdraw
     */
    error InsufficientTokenBalance(uint256 tokenBalance, uint256 amount);
    /**
     * @notice Thrown when attempting to set multipliers with threshold and additionalRate arrays of different lengths.
     * @param thresholdsLength The length of the thresholds array
     * @param additionalRatesLength The length of the additionalRates array
     */
    error MultiplierLengthsMismatched(uint256 thresholdsLength, uint256 additionalRatesLength);
}
