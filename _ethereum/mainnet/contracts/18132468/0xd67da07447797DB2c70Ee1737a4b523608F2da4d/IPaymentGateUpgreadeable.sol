// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPaymentGateUpgreadeable {
    struct PaymentInfo {
        address paymentInToken;
        uint96 paymentInAmount;
        address paymentOutToken;
        uint96 paymentOutAmount;
    }
}
