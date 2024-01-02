// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "./ISimpleVaultInternal.sol";

interface ISimpleVaultAdaptor is ISimpleVaultInternal {
    /**
     * @notice withdraw accrued protocol fees, and send to TREASURY address
     * @param adaptor enum indicating which adaptor to withdraw fees from
     * @return tokenFees an array of all the different fees withdrawn from the adaptor - currently supports up to 3 different tokens
     */
    function withdrawFees(
        LendingAdaptor adaptor
    ) external returns (TokenFee[3] memory tokenFees);

    /**
     * @notice collateralizes an ERC721 asset with a lending vendor in exchange for
     * lending vendor tokens
     * @param adaptor enum indicating which lending vendor to interact with via the respective adaptor
     * @param collateralizationData encoded data needed to collateralize the ERC721 asset
     * @return amount amount of lending vendor token borrowed
     */
    function collateralizeERC721Asset(
        LendingAdaptor adaptor,
        bytes calldata collateralizationData
    ) external returns (uint256 amount);

    /**
     * @notice performs a staking sequence on a given adaptor
     * @param adaptor enum indicating which adaptor will perform staking
     * @param stakeData encoded data required in order to perform staking
     * @return shares amount of staking shares received
     */
    function stake(
        StakingAdaptor adaptor,
        bytes calldata stakeData
    ) external returns (uint256 shares);

    /**
     * @notice unstakes part or all of position from the protocol relating to the adaptor
     * @param adaptor adaptor to use in order to unstake
     * @param unstakeData encoded data required to perform unstaking steps
     * @return tokenAmount amount of tokens returns for unstaking
     */
    function unstake(
        StakingAdaptor adaptor,
        bytes calldata unstakeData
    ) external returns (uint256 tokenAmount);

    /**
     * @notice repays part of the loan owed to a lending vendor for a collateralized position
     * @param adaptor adaptor to use in order to repay loan
     * @param repayData encoded data required to pay back loan portion
     * @return paidDebt amount of debt repaid
     */
    function repayLoan(
        LendingAdaptor adaptor,
        bytes calldata repayData
    ) external returns (uint256 paidDebt);

    /**
     * @notice liquidates entire position in a lending vendor in order to pay back debt
     * and converts any surplus ETH and reward tokens into yield
     * @param adaptor adaptor to use in order to close position
     * @param closeData encoded data required to close lending vendor position
     * @return eth amount of ETH received after closing position
     */
    function closePosition(
        LendingAdaptor adaptor,
        bytes calldata closeData
    ) external returns (uint256 eth);

    /**
     * @notice directly closes a position to withdraw collateral, assumes position has already been repaid
     * @param adaptor adaptor to use in order to directly close position & withdraw collateral
     * @param directCloseData encoded data required to directly close lending vendor position & withdraw collateral
     */
    function directClosePosition(
        LendingAdaptor adaptor,
        bytes calldata directCloseData
    ) external;

    /**
     * @notice makes loan repayment for a collateralized ERC721 asset using vault funds
     * @param adaptor adaptor to use in order to make loan repayment
     * @param directRepayData encoded data needed to directly repay loan
     */
    function directRepayLoan(
        LendingAdaptor adaptor,
        bytes calldata directRepayData
    ) external;

    /**
     * @notice directly provides and/or claims rewards to provide as yield to users
     * @param adaptor adaptor to use in order to directly provide and/or claim rewards
     * @param directYieldData encoded data required in order to perform direct reward providing & claiming
     */
    function directProvideYield(
        StakingAdaptor adaptor,
        bytes calldata directYieldData
    ) external payable;

    /**
     * @notice converts part of position and/or claims rewards to provide as yield to users
     * @param adaptor adaptor to use in order liquidate convert part of position and/or claim rewards
     * @param unstakeData encoded data required in order to perform unstaking of position and reward claiming
     */
    function provideYield(
        StakingAdaptor adaptor,
        bytes calldata unstakeData
    ) external;
}
