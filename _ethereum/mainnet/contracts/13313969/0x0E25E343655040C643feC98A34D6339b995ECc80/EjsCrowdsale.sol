// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "./Pausable.sol";
import "./CappedTokenSoldCrowdsaleHelper.sol";
import "./IndividuallyCappedCrowdsaleHelper.sol";
import "./TimedCrowdsaleHelper.sol";
import "./VestedCrowdsale.sol";
import "./WhitelistCrowdsaleHelper.sol";
import "./IEjsCrowdsale.sol";

/**
 * @title EjsCrowdsale
 * @author Enjinstarter
 * @dev Crowdsale where tokens are minted in each purchase.
 */
contract EjsCrowdsale is
    VestedCrowdsale,
    CappedTokenSoldCrowdsaleHelper,
    IndividuallyCappedCrowdsaleHelper,
    TimedCrowdsaleHelper,
    WhitelistCrowdsaleHelper,
    Pausable,
    IEjsCrowdsale
{
    using SafeMath for uint256;

    struct EjsCrowdsaleInfo {
        uint256 tokenCap;
        address vestingContract;
        address whitelistContract;
    }

    address public governanceAccount;
    address public crowdsaleAdmin;

    // max 20 lots (USD4000 worth of tokens being sold equivalent to 500000 tokens)
    constructor(
        address wallet_,
        address tokenSelling_,
        EjsCrowdsaleInfo memory crowdsaleInfo,
        LotsInfo memory lotsInfo,
        Timeframe memory timeframe,
        PaymentTokenInfo[] memory paymentTokensInfo
    )
        Crowdsale(wallet_, tokenSelling_, lotsInfo, paymentTokensInfo)
        VestedCrowdsale(crowdsaleInfo.vestingContract)
        CappedTokenSoldCrowdsaleHelper(crowdsaleInfo.tokenCap)
        IndividuallyCappedCrowdsaleHelper(
            lotsInfo.maxLots.mul(lotsInfo.lotSize).mul(TOKEN_SELLING_SCALE)
        )
        TimedCrowdsaleHelper(timeframe)
        WhitelistCrowdsaleHelper(crowdsaleInfo.whitelistContract)
    {
        governanceAccount = msg.sender;
        crowdsaleAdmin = msg.sender;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "EjsCrowdsale: sender unauthorized");
        _;
    }

    /**
     * @return availableLots Available number of lots for beneficiary
     */
    function getAvailableLotsFor(address beneficiary)
        external
        view
        override
        returns (uint256 availableLots)
    {
        if (!whitelisted(beneficiary)) {
            return 0;
        }

        availableLots = _getAvailableTokensFor(beneficiary).div(lotSize()).div(
            TOKEN_SELLING_SCALE
        );
    }

    /**
     * @return remainingLots Remaining number of lots for crowdsale
     */
    function getRemainingLots()
        external
        view
        override
        returns (uint256 remainingLots)
    {
        uint256 remainingTokens = tokenCap().sub(tokensSold);
        remainingLots = remainingTokens.div(lotSize());
    }

    function pause() external override onlyBy(crowdsaleAdmin) {
        _pause();
    }

    function unpause() external override onlyBy(crowdsaleAdmin) {
        _unpause();
    }

    function extendTime(uint256 newClosingTime)
        external
        override
        onlyBy(crowdsaleAdmin)
    {
        _extendTime(newClosingTime);
    }

    function startDistribution(uint256 scheduleStartTimestamp)
        external
        override
        onlyBy(crowdsaleAdmin)
    {
        require(
            scheduleStartTimestamp > closingTime(),
            "EjsCrowdsale: must be after closing time"
        );
        _startDistribution(scheduleStartTimestamp);
    }

    function setGovernanceAccount(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "EjsCrowdsale: zero account");

        governanceAccount = account;
    }

    function setCrowdsaleAdmin(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "EjsCrowdsale: zero account");

        crowdsaleAdmin = account;
    }

    /**
     * @param beneficiary Token beneficiary
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount of wei contributed
     * @param tokenAmount Number of tokens to be purchased
     */
    function _preValidatePurchase(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    )
        internal
        view
        override
        tokenCapNotExceeded(tokensSold, tokenAmount)
        beneficiaryCapNotExceeded(beneficiary, tokenAmount)
        whenNotPaused
        onlyWhileOpen
        isWhitelisted(beneficiary)
    {
        super._preValidatePurchase(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );
    }

    /**
     * @dev Extend parent behavior to update purchased amount of tokens by beneficiary.
     * @param beneficiary Token purchaser
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _updatePurchasingState(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal override {
        super._updatePurchasingState(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );

        _updateBeneficiaryTokensPurchased(beneficiary, tokenAmount);
    }
}
