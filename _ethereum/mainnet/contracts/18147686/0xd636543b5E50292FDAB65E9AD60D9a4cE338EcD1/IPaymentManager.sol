// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPaymentManager {
    function getPaymentMethodFees(address paymentMethodAddress)
        external
        view
        returns (uint256 takerFee, uint256 makerFee);

    function isPaymentMethodSupported(address paymentMethodAddress)
        external
        view
        returns (bool);

    function updateSupportedPaymentMethod(
        address paymentMethodAddress,
        bool isEnabled
    ) external;

    function updatePaymentMethodFees(
        address paymentMethodAddress,
        uint256 makerFee,
        uint256 takerFee
    ) external;
}
