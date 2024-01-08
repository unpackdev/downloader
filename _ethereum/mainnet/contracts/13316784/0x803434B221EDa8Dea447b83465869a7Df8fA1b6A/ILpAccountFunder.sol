// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Imports.sol";

/**
 * @notice Facilitate lending liquidity to the LP Account from pools
 */
interface ILpAccountFunder {
    /**
     * @notice Log when liquidity is lent to the LP Account
     * @param poolIds An array of address registry IDs for pools that lent
     * @param amounts An array of the amount each pool lent
     */
    event FundLpAccount(bytes32[] poolIds, uint256[] amounts);

    /**
     * @notice Log when liquidity is repaid to the pools
     * @param poolIds An array of address registry IDs for pools were repaid
     * @param amounts An array of the amount each pool was repaid
     */
    event WithdrawFromLpAccount(bytes32[] poolIds, uint256[] amounts);

    /**
     * @notice Log when liquidity is lent to the LP Account
     * @param pools An array of address registry IDs for pools that lent
     * @param amounts An array of the amount each pool lent
     */
    event EmergencyFundLpAccount(IReservePool[] pools, uint256[] amounts);

    /**
     * @notice Log when liquidity is repaid to the pools
     * @param pools An array of address registry IDs for pools were repaid
     * @param amounts An array of the amount each pool was repaid
     */
    event EmergencyWithdrawFromLpAccount(
        IReservePool[] pools,
        uint256[] amounts
    );

    /**
     * @notice Lend liquidity to the LP Account from pools
     * @dev Should calculate excess liquidity that can be lent
     * @param pools An array of address registry IDs for pools that lent
     */
    function fundLpAccount(bytes32[] calldata pools) external;

    /**
     * @notice Lend liquidity to the LP Account from pools
     * @notice Only used in emergencies
     * @dev Should only be callable by the Admin Safe
     * @dev Can lend any arbitrary amount of liquidity
     * @param pools An array of address registry IDs for pools that lent
     * @param amounts An array of amounts to borrow from each pool
     */
    function emergencyFundLpAccount(
        IReservePool[] calldata pools,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Repay liquidity borrowed by the LP Account
     * @dev Should repay enough to fill up the pools' reserves
     * @param pools An array of address registry IDs for pools that were repaid
     */
    function withdrawFromLpAccount(bytes32[] calldata pools) external;

    /**
     * @notice Repay liquidity borrowed by the LP Account
     * @notice Only used in emergencies
     * @dev Should only be callable by the Admin Safe
     * @dev Can repay any arbitrary amount of liquidity
     * @param pools An array of address registry IDs for pools that were repaid
     * @param amounts An array of amounts to repay to each pool
     */
    function emergencyWithdrawFromLpAccount(
        IReservePool[] calldata pools,
        uint256[] calldata amounts
    ) external;
}
