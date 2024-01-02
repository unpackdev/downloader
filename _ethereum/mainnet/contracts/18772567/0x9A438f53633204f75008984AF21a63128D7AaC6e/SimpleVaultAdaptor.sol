// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "./SimpleVaultInternal.sol";
import "./ISimpleVaultAdaptor.sol";

contract SimpleVaultAdaptor is SimpleVaultInternal, ISimpleVaultAdaptor {
    constructor(
        address feeRecipient,
        address dawnOfInsrt
    ) SimpleVaultInternal(feeRecipient, dawnOfInsrt) {}

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function withdrawFees(
        LendingAdaptor adaptor
    ) external onlyProtocolOwner returns (TokenFee[3] memory tokenFees) {
        tokenFees = _withdrawFees(adaptor);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function collateralizeERC721Asset(
        LendingAdaptor adaptor,
        bytes calldata collateralizationData
    ) external onlyProtocolOwner returns (uint256 amount) {
        amount = _collateralizeERC721Asset(adaptor, collateralizationData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function stake(
        StakingAdaptor adaptor,
        bytes calldata stakeData
    ) external onlyProtocolOwner returns (uint256 shares) {
        shares = _stake(adaptor, stakeData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function unstake(
        StakingAdaptor adaptor,
        bytes calldata unstakeData
    ) external onlyProtocolOwner returns (uint256 tokenAmount) {
        tokenAmount = _unstake(adaptor, unstakeData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function repayLoan(
        LendingAdaptor adaptor,
        bytes calldata repayData
    ) external onlyAuthorized returns (uint256 paidDebt) {
        paidDebt = _repayLoan(adaptor, repayData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function closePosition(
        LendingAdaptor adaptor,
        bytes calldata closeData
    ) external onlyProtocolOwner returns (uint256 eth) {
        eth = _closePosition(adaptor, closeData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function directClosePosition(
        LendingAdaptor adaptor,
        bytes calldata directCloseData
    ) external onlyProtocolOwner {
        _directClosePosition(adaptor, directCloseData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function directRepayLoan(
        LendingAdaptor adaptor,
        bytes calldata directRepayData
    ) external onlyProtocolOwner {
        _directRepayLoan(adaptor, directRepayData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function directProvideYield(
        StakingAdaptor adaptor,
        bytes calldata directYieldData
    ) external payable onlyProtocolOwner {
        _provideYield(adaptor, directYieldData);
    }

    /**
     * @inheritdoc ISimpleVaultAdaptor
     */
    function provideYield(
        StakingAdaptor adaptor,
        bytes calldata unstakeData
    ) external onlyProtocolOwner {
        _provideYield(adaptor, unstakeData);
    }
}
