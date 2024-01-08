// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "./Pausable.sol";
import "./CappedTokenSoldCrowdsaleHelper.sol";
import "./LaunchpadWhitelistCrowdsaleHelper.sol";
import "./HoldErc20TokenCrowdsaleHelper.sol";
import "./NoDeliveryCrowdsale.sol";
import "./TimedCrowdsaleHelper.sol";
import "./VestedCrowdsale.sol";
import "./ILaunchpadCrowdsaleWithVesting.sol";

/**
 * @title LaunchpadCrowdsaleWithVesting
 * @author Enjinstarter
 * @dev Launchpad crowdsale where there is no delivery of tokens in each purchase.
 */
contract LaunchpadCrowdsaleWithVesting is
    VestedCrowdsale,
    CappedTokenSoldCrowdsaleHelper,
    HoldErc20TokenCrowdsaleHelper,
    TimedCrowdsaleHelper,
    LaunchpadWhitelistCrowdsaleHelper,
    Pausable,
    ILaunchpadCrowdsaleWithVesting
{
    using SafeMath for uint256;

    struct LaunchpadCrowdsaleInfo {
        uint256 tokenCap;
        address vestingContract;
        address whitelistContract;
        address tokenHold;
        uint256 minTokenHoldAmount;
    }

    address public governanceAccount;
    address public crowdsaleAdmin;

    // max 1 lot
    constructor(
        address wallet_,
        address tokenSelling_,
        LaunchpadCrowdsaleInfo memory crowdsaleInfo,
        LotsInfo memory lotsInfo,
        Timeframe memory timeframe,
        PaymentTokenInfo[] memory paymentTokensInfo
    )
        Crowdsale(wallet_, tokenSelling_, lotsInfo, paymentTokensInfo)
        VestedCrowdsale(crowdsaleInfo.vestingContract)
        CappedTokenSoldCrowdsaleHelper(crowdsaleInfo.tokenCap)
        HoldErc20TokenCrowdsaleHelper(
            crowdsaleInfo.tokenHold,
            crowdsaleInfo.minTokenHoldAmount
        )
        TimedCrowdsaleHelper(timeframe)
        LaunchpadWhitelistCrowdsaleHelper(crowdsaleInfo.whitelistContract)
    {
        governanceAccount = msg.sender;
        crowdsaleAdmin = msg.sender;
    }

    modifier onlyBy(address account) {
        require(
            msg.sender == account,
            "LaunchpadCrowdsaleWithVesting: sender unauthorized"
        );
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

        availableLots = _getAvailableTokensFor(beneficiary).div(
            getBeneficiaryCap(beneficiary)
        );
    }

    /**
     * @return remainingTokens Remaining number of tokens for crowdsale
     */
    function getRemainingTokens()
        external
        view
        override
        returns (uint256 remainingTokens)
    {
        remainingTokens = tokenCap().sub(tokensSold);
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
            "LaunchpadCrowdsaleWithVesting: must be after closing time"
        );
        _startDistribution(scheduleStartTimestamp);
    }

    function setGovernanceAccount(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(
            account != address(0),
            "LaunchpadCrowdsaleWithVesting: zero account"
        );

        governanceAccount = account;
    }

    function setCrowdsaleAdmin(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(
            account != address(0),
            "LaunchpadCrowdsaleWithVesting: zero account"
        );

        crowdsaleAdmin = account;
    }

    /**
     * @param beneficiary Address receiving the tokens
     * @return lotSize_ lot size of token being sold
     */
    function _lotSize(address beneficiary)
        internal
        view
        override
        returns (uint256 lotSize_)
    {
        lotSize_ = getBeneficiaryCap(beneficiary);
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param lots Number of lots of token being sold
     * @param beneficiary Address receiving the tokens
     * @return tokenAmount Number of tokens that will be purchased
     */
    function _getTokenAmount(uint256 lots, address beneficiary)
        internal
        view
        override
        returns (uint256 tokenAmount)
    {
        tokenAmount = lots.mul(_lotSize(beneficiary));
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
        whenNotPaused
        onlyWhileOpen
        tokenCapNotExceeded(tokensSold, tokenAmount)
        holdsSufficientTokens(beneficiary)
        isWhitelisted(beneficiary)
    {
        // TODO: Investigate why modifier and require() don't work consistently for beneficiaryCapNotExceeded()
        if (
            getTokensPurchasedBy(beneficiary).add(tokenAmount) >
            getBeneficiaryCap(beneficiary)
        ) {
            revert("LaunchpadCrowdsaleWithVesting: beneficiary cap exceeded");
        }

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
