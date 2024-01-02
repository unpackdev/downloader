// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
/* Gambulls LibDirectTransfer 2023 */

import "./LibOrder.sol";

library LibDirectTransfer {
    struct Purchase {
        address sellOrderMaker;
        uint256 sellOrderNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 sellOrderPaymentAmount;
        address paymentToken;
        uint256 sellOrderSalt;
        uint256 sellOrderStart;
        uint256 sellOrderEnd;
        bytes4 sellOrderType;
        bytes sellOrderData;
        bytes sellOrderSignature;

        uint256 buyOrderPaymentAmount;
        uint256 buyOrderNftAmount;
        bytes buyOrderData;
    }

    struct AcceptOffer {
        address bidOrderMaker;
        uint256 bidOrderNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 bidOrderPaymentAmount;
        address paymentToken;
        uint256 bidOrderSalt;
        uint256 bidOrderStart;
        uint256 bidOrderEnd;
        bytes4 bidOrderType;
        bytes bidOrderData;
        bytes bidOrderSignature;

        uint256 sellOrderPaymentAmount;
        uint256 sellOrderNftAmount;
        bytes sellOrderData;
    }
}