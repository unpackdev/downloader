// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import "./Imports.sol";

/**
 * @notice For pools that locked value between accounts
 * @dev Shares are accounted for using the `APT` token
 */
interface IPoolToken {
    /**
     * @notice Log a token deposit
     * @param sender Address of the depositor account
     * @param token Token deposited
     * @param tokenAmount The amount of tokens deposited
     * @param aptMintAmount Number of shares received
     * @param tokenEthValue Total value of the deposit
     * @param totalEthValueLocked Total value of the pool
     */
    event DepositedAPT(
        address indexed sender,
        IDetailedERC20 token,
        uint256 tokenAmount,
        uint256 aptMintAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );

    /**
     * @notice Log a token withdrawal
     * @param sender Address of the withdrawal account
     * @param token Token withdrawn
     * @param redeemedTokenAmount The amount of tokens withdrawn
     * @param aptRedeemAmount Number of shares redeemed
     * @param tokenEthValue Total value of the withdrawal
     * @param totalEthValueLocked Total value of the pool
     */
    event RedeemedAPT(
        address indexed sender,
        IDetailedERC20 token,
        uint256 redeemedTokenAmount,
        uint256 aptRedeemAmount,
        uint256 tokenEthValue,
        uint256 totalEthValueLocked
    );

    /**
     * @notice Add liquidity for a share of the pool
     * @param amount Amount to deposit of the underlying stablecoin
     */
    function addLiquidity(uint256 amount) external;

    /**
     * @notice Redeem shares of the pool to withdraw liquidity
     * @param tokenAmount The amount of shares to redeem
     */
    function redeem(uint256 tokenAmount) external;

    /**
     * @notice Determine the share received for a deposit
     * @param depositAmount The size of the deposit
     * @return The number of shares
     */
    function calculateMintAmount(uint256 depositAmount)
        external
        view
        returns (uint256);

    /**
     * @notice How many tokens can be withdrawn with an amount of shares
     * @notice Accounts for early withdrawal fee
     * @param aptAmount The amount of shares
     * @return The amount of tokens
     */
    function getUnderlyerAmountWithFee(uint256 aptAmount)
        external
        view
        returns (uint256);

    /**
     * @notice How many tokens can be withdrawn with an amount of shares
     * @param aptAmount The amount of shares
     * @return The amount of tokens
     */
    function getUnderlyerAmount(uint256 aptAmount)
        external
        view
        returns (uint256);

    /**
     * @notice Get the total USD value of an amount of shares
     * @param aptAmount The amount of shares
     * @return The total USD value of the shares
     */
    function getAPTValue(uint256 aptAmount) external view returns (uint256);
}
