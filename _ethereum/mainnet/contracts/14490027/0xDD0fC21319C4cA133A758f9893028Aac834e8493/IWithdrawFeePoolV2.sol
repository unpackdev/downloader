// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

/**
 * @notice For pools that can charge an early withdraw fee
 */
interface IWithdrawFeePoolV2 {
    /**
     * @notice Log when the arbitrage fee period changes
     * @param arbitrageFeePeriod The new period
     */
    event ArbitrageFeePeriodChanged(uint256 arbitrageFeePeriod);

    /**
     * @notice Log when the arbitrage fee percentage changes
     * @param arbitrageFee The new fee
     */
    event ArbitrageFeeChanged(uint256 arbitrageFee);

    /**
     * @notice Log when the withdraw fee changes
     * @param withdrawFee The new fee
     */
    event WithdrawFeeChanged(uint256 withdrawFee);

    /**
     * @notice Set the new arbitrage fee and period
     * @param arbitrageFee The new fee in percentage points
     * @param arbitrageFeePeriod The new period in seconds
     */
    function setArbitrageFee(uint256 arbitrageFee, uint256 arbitrageFeePeriod)
        external;

    /**
     * @notice Set the new withdraw fee
     * @param withdrawFee The new withdraw fee
     */
    function setWithdrawFee(uint256 withdrawFee) external;

    /**
     * @notice Get the period of time a withdrawal will be considered early
     * @notice An early withdrawal gets a fee as protection against arbitrage.
     * @notice The period starts from the time of the last deposit for an account
     * @return The time in seconds
     */
    function arbitrageFeePeriod() external view returns (uint256);

    /**
     * @notice Get the fee charged to protect against arbitrage in percentage points.
     * @return The arbitrage fee
     */
    function arbitrageFee() external view returns (uint256);

    /**
     *@notice Get the fee charged for all withdrawals in 1/100th basis points,
     * e.g. 100 = 1 bps
     * @return The withdraw fee
     */
    function withdrawFee() external view returns (uint256);

    /**
     * @notice Check if caller will be charged early withdraw fee
     * @return `true` when fee will apply, `false` when it won't
     */
    function isEarlyRedeem() external view returns (bool);
}
