// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "./SafeERC20.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ICrowdsale.sol";

/**
 * @title Crowdsale
 * @author Enjinstarter
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ERC20 tokens. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard, ICrowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_NUM_PAYMENT_TOKENS = 10;
    uint256 public constant TOKEN_MAX_DECIMALS = 18;
    uint256 public constant TOKEN_SELLING_SCALE = 10**TOKEN_MAX_DECIMALS;

    // Amount of tokens sold
    uint256 public tokensSold;

    // The token being sold
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-are-too-similar
    // slither-disable-next-line similar-names
    address private _tokenSelling;

    // Lot size and maximum number of lots for token being sold
    LotsInfo private _lotsInfo;

    // Payment tokens
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-are-too-similar
    // slither-disable-next-line similar-names
    address[] private _paymentTokens;

    // Payment token decimals
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-are-too-similar
    // slither-disable-next-line similar-names
    mapping(address => uint256) private _paymentDecimals;

    // Indicates whether ERC20 token is acceptable for payment
    mapping(address => bool) private _isPaymentTokens;

    // Address where funds are collected
    address private _wallet;

    // How many weis one token costs for each ERC20 payment token
    mapping(address => uint256) private _rates;

    // Amount of wei raised for each payment token
    mapping(address => uint256) private _weiRaised;

    /**
     * @dev Rates will denote how many weis one token costs for each ERC20 payment token.
     * For USDC or USDT payment token which has 6 decimals, minimum rate will
     * be 1000000000000 which will correspond to a price of USD0.000001 per token.
     * @param wallet_ Address where collected funds will be forwarded to
     * @param tokenSelling_ Address of the token being sold
     * @param lotsInfo Lot size and maximum number of lots for token being sold
     * @param paymentTokensInfo Addresses, decimals, rates and lot sizes of ERC20 tokens acceptable for payment
     */
    constructor(
        address wallet_,
        address tokenSelling_,
        LotsInfo memory lotsInfo,
        PaymentTokenInfo[] memory paymentTokensInfo
    ) {
        require(wallet_ != address(0), "Crowdsale: zero wallet address");
        require(
            tokenSelling_ != address(0),
            "Crowdsale: zero token selling address"
        );
        require(lotsInfo.lotSize > 0, "Crowdsale: zero lot size");
        require(lotsInfo.maxLots > 0, "Crowdsale: zero max lots");
        require(paymentTokensInfo.length > 0, "Crowdsale: zero payment tokens");
        require(
            paymentTokensInfo.length < MAX_NUM_PAYMENT_TOKENS,
            "Crowdsale: exceed max payment tokens"
        );

        _wallet = wallet_;
        _tokenSelling = tokenSelling_;
        _lotsInfo = lotsInfo;

        for (uint256 i = 0; i < paymentTokensInfo.length; i++) {
            uint256 paymentDecimal = paymentTokensInfo[i].paymentDecimal;
            require(
                paymentDecimal <= TOKEN_MAX_DECIMALS,
                "Crowdsale: decimals exceed 18"
            );
            address paymentToken = paymentTokensInfo[i].paymentToken;
            require(
                paymentToken != address(0),
                "Crowdsale: zero payment token address"
            );
            uint256 rate_ = paymentTokensInfo[i].rate;
            require(rate_ > 0, "Crowdsale: zero rate");

            _isPaymentTokens[paymentToken] = true;
            _paymentTokens.push(paymentToken);
            _paymentDecimals[paymentToken] = paymentDecimal;
            _rates[paymentToken] = rate_;
        }
    }

    /**
     * @return tokenSelling_ the token being sold
     */
    function tokenSelling()
        external
        view
        override
        returns (address tokenSelling_)
    {
        tokenSelling_ = _tokenSelling;
    }

    /**
     * @return wallet_ the address where funds are collected
     */
    function wallet() external view override returns (address wallet_) {
        wallet_ = _wallet;
    }

    /**
     * @return paymentTokens_ the payment tokens
     */
    function paymentTokens()
        external
        view
        override
        returns (address[] memory paymentTokens_)
    {
        paymentTokens_ = _paymentTokens;
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return rate_ how many weis one token costs for specified ERC20 payment token
     */
    function rate(address paymentToken)
        external
        view
        override
        returns (uint256 rate_)
    {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        rate_ = _rate(paymentToken);
    }

    /**
     * @return lotSize_ lot size of token being sold
     */
    function lotSize() public view override returns (uint256 lotSize_) {
        lotSize_ = _lotsInfo.lotSize;
    }

    /**
     * @return maxLots_ maximum number of lots for token being sold
     */
    function maxLots() external view override returns (uint256 maxLots_) {
        maxLots_ = _lotsInfo.maxLots;
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return weiRaised_ the amount of wei raised
     */
    function weiRaisedFor(address paymentToken)
        external
        view
        override
        returns (uint256 weiRaised_)
    {
        weiRaised_ = _weiRaisedFor(paymentToken);
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return isPaymentToken_ whether token is accepted for payment
     */
    function isPaymentToken(address paymentToken)
        public
        view
        override
        returns (bool isPaymentToken_)
    {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );

        isPaymentToken_ = _isPaymentTokens[paymentToken];
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param lots Number of lots of token being sold
     * @return tokenAmount Number of tokens being sold that will be purchased
     */
    function getTokenAmount(uint256 lots)
        external
        view
        override
        returns (uint256 tokenAmount)
    {
        require(lots > 0, "Crowdsale: zero lots");

        tokenAmount = _getTokenAmount(lots);
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     * @return weiAmount Amount in wei of ERC20 payment token
     */
    function getWeiAmount(address paymentToken, uint256 lots)
        external
        view
        override
        returns (uint256 weiAmount)
    {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(lots > 0, "Crowdsale: zero lots");
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        weiAmount = _getWeiAmount(paymentToken, lots);
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     */
    function buyTokens(address paymentToken, uint256 lots) external override {
        _buyTokensFor(msg.sender, paymentToken, lots);
    }

    /**
     * @param beneficiary Recipient of the token purchase
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     */
    function buyTokensFor(
        address beneficiary,
        address paymentToken,
        uint256 lots
    ) external override {
        _buyTokensFor(beneficiary, paymentToken, lots);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     */
    function _buyTokensFor(
        address beneficiary,
        address paymentToken,
        uint256 lots
    ) internal nonReentrant {
        require(
            beneficiary != address(0),
            "Crowdsale: zero beneficiary address"
        );
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(lots > 0, "Crowdsale: zero lots");
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        // calculate token amount to be created
        uint256 tokenAmount = _getTokenAmount(lots);
        // calculate wei amount to transfer to wallet
        uint256 weiAmount = _getWeiAmount(paymentToken, lots);

        _preValidatePurchase(beneficiary, paymentToken, weiAmount, tokenAmount);

        // update state
        _weiRaised[paymentToken] = _weiRaised[paymentToken].add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

        _updatePurchasingState(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );

        emit TokensPurchased(
            msg.sender,
            beneficiary,
            paymentToken,
            lots,
            weiAmount,
            tokenAmount
        );

        _processPurchase(beneficiary, tokenAmount);
        _forwardFunds(paymentToken, weiAmount);
        _postValidatePurchase(
            beneficiary,
            paymentToken,
            weiAmount,
            tokenAmount
        );
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return weiRaised_ the amount of wei raised
     */
    function _weiRaisedFor(address paymentToken)
        internal
        view
        virtual
        returns (uint256 weiRaised_)
    {
        require(
            paymentToken != address(0),
            "Crowdsale: zero payment token address"
        );
        require(
            isPaymentToken(paymentToken),
            "Crowdsale: payment token unaccepted"
        );

        weiRaised_ = _weiRaised[paymentToken];
    }

    /**
     * @param paymentToken ERC20 payment token address
     * @return rate_ how many weis one token costs for specified ERC20 payment token
     */
    function _rate(address paymentToken)
        internal
        view
        virtual
        returns (uint256 rate_)
    {
        rate_ = _rates[paymentToken];
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _preValidatePurchase(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo/rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _postValidatePurchase(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function _deliverTokens(address beneficiary, uint256 tokenAmount)
        internal
        virtual
    {
        IERC20(_tokenSelling).safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount)
        internal
        virtual
    {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param paymentToken ERC20 payment token address
     * @param weiAmount Amount in wei of ERC20 payment token
     * @param tokenAmount Number of tokens to be purchased
     */
    function _updatePurchasingState(
        address beneficiary,
        address paymentToken,
        uint256 weiAmount,
        uint256 tokenAmount
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param lots Number of lots of token being sold
     * @return tokenAmount Number of tokens that will be purchased
     */
    function _getTokenAmount(uint256 lots)
        internal
        view
        virtual
        returns (uint256 tokenAmount)
    {
        tokenAmount = lots.mul(_lotsInfo.lotSize).mul(TOKEN_SELLING_SCALE);
    }

    /**
     * @dev Override to extend the way in which payment token is converted to tokens.
     * @param paymentToken ERC20 payment token address
     * @param lots Number of lots of token being sold
     * @return weiAmount Amount in wei of ERC20 payment token
     */
    function _getWeiAmount(address paymentToken, uint256 lots)
        internal
        view
        virtual
        returns (uint256 weiAmount)
    {
        uint256 rate_ = _rate(paymentToken);
        uint256 tokenAmount = _getTokenAmount(lots);
        weiAmount = tokenAmount.mul(rate_).div(TOKEN_SELLING_SCALE);
    }

    /**
     * @dev Determines how ERC20 payment token is stored/forwarded on purchases.
     */
    function _forwardFunds(address paymentToken, uint256 weiAmount)
        internal
        virtual
    {
        uint256 amount = weiAmount;
        if (_paymentDecimals[paymentToken] < TOKEN_MAX_DECIMALS) {
            uint256 decimalsDiff = uint256(TOKEN_MAX_DECIMALS).sub(
                _paymentDecimals[paymentToken]
            );
            amount = weiAmount.div(10**decimalsDiff);
        }

        IERC20(paymentToken).safeTransferFrom(msg.sender, _wallet, amount);
    }
}
