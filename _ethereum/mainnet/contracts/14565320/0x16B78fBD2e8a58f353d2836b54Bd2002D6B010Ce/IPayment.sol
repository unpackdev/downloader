// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

interface IPayment {
    enum PaymentToken {
        SENTINEL,
        WETH,
        USDC,
        DAI,
        USDT,
        TUSD,
        RENT
    }

    function getPaymentToken(uint8 index) external view returns (address);

    function setPaymentToken(uint8 index, address currencyAddress) external;
}
