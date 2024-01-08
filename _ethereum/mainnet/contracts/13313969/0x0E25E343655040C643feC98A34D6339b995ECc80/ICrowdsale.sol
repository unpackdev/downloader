// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./IERC20.sol";

/**
 * @title ICrowdsale
 * @author Enjinstarter
 */
interface ICrowdsale {
    struct LotsInfo {
        uint256 lotSize;
        uint256 maxLots;
    }

    struct PaymentTokenInfo {
        address paymentToken;
        uint256 paymentDecimal;
        uint256 rate;
    }

    function tokenSelling() external view returns (address tokenSelling_);

    function wallet() external view returns (address wallet_);

    function paymentTokens()
        external
        view
        returns (address[] memory paymentTokens_);

    function rate(address paymentToken) external view returns (uint256 rate_);

    function lotSize() external view returns (uint256 lotSize_);

    function maxLots() external view returns (uint256 maxLots_);

    function weiRaisedFor(address paymentToken)
        external
        view
        returns (uint256 weiRaised_);

    function isPaymentToken(address paymentToken)
        external
        view
        returns (bool isPaymentToken_);

    function getTokenAmount(uint256 lots)
        external
        view
        returns (uint256 tokenAmount);

    function getWeiAmount(address paymentToken, uint256 lots)
        external
        view
        returns (uint256 weiAmount);

    function buyTokens(address paymentToken, uint256 lots) external;

    function buyTokensFor(
        address beneficiary,
        address paymentToken,
        uint256 lots
    ) external;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param paymentToken address of ERC20 token used for payment
     * @param lots number of lots to purchase
     * @param weiAmount weis paid for purchase
     * @param tokenAmount amount of tokens purchased
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        address indexed paymentToken,
        uint256 lots,
        uint256 weiAmount,
        uint256 tokenAmount
    );
}
