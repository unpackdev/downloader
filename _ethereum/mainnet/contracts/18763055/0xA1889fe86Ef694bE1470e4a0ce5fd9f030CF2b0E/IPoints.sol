// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./IPointsEvents.sol";
import "./IPointsErrors.sol";

/**
 * @title IPoints
 * @notice Interface for the Points contract.
 * @dev Does not support fee-on-transfer or rebasing tokens (in unwrapped form).
 */
interface IPoints is IERC20, IPointsEvents, IPointsErrors {
    /**
     * @notice Returns true if transfers are paused.
     * @return paused_ True if transfers are paused. False otherwise.
     */
    function paused() external view returns (bool paused_);

    /**
     * @notice Sets the paused status of the transfers.
     * @param paused_ The new paused status.
     */
    function setPaused(bool paused_) external;

    /**
     * @notice Returns true if the account is whitelisted.
     * @param account The address to check.
     * @return whitelisted True if the account is whitelisted. False otherwise.
     */
    function isWhitelisted(address account) external view returns (bool whitelisted);

    /**
     * @notice Updates the whitelist status of the account.
     * @param account The address to update.
     * @param status The new whitelist status.
     */
    function setAddressWhitelist(address account, bool status) external;

    /**
     * @notice Returns the token at the given index in the token list
     * @dev Tokens that have rates set to 0 are still included in the list.
     * @param index The index of the token in the list.
     * @return token The token
     */
    function tokenAt(uint256 index) external view returns (address token);

    /**
     * @notice Returns the number of tokens in the token list.
     * @dev Tokens that have rates set to 0 are still included in the list.
     * @return count The number of tokens in the list.
     */
    function tokenCount() external view returns (uint256 count);

    /**
     * @notice Sets the rates of the tokens. New tokens will be added if they do not already exist.
     * @dev Token addresses and rates are matched by corresponding index in their respective arrays
     * @dev Passing in the same token address multiple times results in only the final value being used.
     * @param tokens The addresses of the tokens.
     * @param rates The rates of the tokens.
     */
    function setRates(address[] calldata tokens, uint96[] calldata rates) external;

    /**
     * @notice Returns the rate of the token and the timestamp of the last update.
     * @param token The address of the token.
     * @return rate The rate of the token.
     * @return timestamp The timestamp of the last rate update or transfer of the token.
     * @return cumulativeRate The cumulative rate snapshot at the timestamp.
     */
    function getRateInfo(address token) external view returns (uint96 rate, uint32 timestamp, uint128 cumulativeRate);

    /**
     * @notice Returns the multiplier thresholds and scalars for the token.
     * @param token The address of the token.
     * @return thresholds The absolute thresholds for the multipliers.
     * @return scalars The absolute scalars for the multipliers.
     */
    function getMultipliers(address token)
        external
        view
        returns (uint128[] memory thresholds, uint128[] memory scalars);

    /**
     * @notice Sets the multiplier thresholds and scalars for the token.
     * @dev To generate the stored absolute thresholds, each iterative threshold is added to the previous one, starting from 0
     * @dev To generate the stored absolute scalars, each iterative scalar is added by the previous one, starting from RATE_DENOMINATOR
     * @param token The address of the token.
     * @param iterativeThresholds The iterative thresholds for the multipliers. Base threshold is 0
     * @param iterativeScalars The iterative scalars for the multipliers. Base multiplier is RATE_DENOMINATOR.
     */
    function setMultipliers(address token, uint128[] calldata iterativeThresholds, uint128[] calldata iterativeScalars)
        external;

    /**
     * @notice Deposits tokens into the contract.
     * @param token The address of the token.
     * @param amount The amount of tokens to deposit.
     */
    function depositToken(address token, uint128 amount) external;

    /**
     * @notice Withdraws tokens from the contract.
     * @param token The address of the token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawToken(address token, uint128 amount) external;

    /**
     * @notice Returns the pending balance of the account (points that have yet to be converted)
     * @param account The address of the account.
     * @return pendingBalance The pending balance of the account.
     */
    function pendingBalanceOf(address account) external view returns (uint256 pendingBalance);

    /**
     * @notice Returns the staked amount for a given account and token
     * @param account The address of the account.
     * @param token The address of the token.
     * @return amount The staked amount for the account and token.
     */
    function getTokenStake(address account, address token) external view returns (uint128 amount);

    /**
     * @notice Returns the current multiplier scalar for a given account and token
     * @param account The address of the account.
     * @param token The address of the token.
     * @return rateScalar The current multiplier scalar for the account and token.
     */
    function getTokenMultiplier(address account, address token) external view returns (uint256 rateScalar);
}
