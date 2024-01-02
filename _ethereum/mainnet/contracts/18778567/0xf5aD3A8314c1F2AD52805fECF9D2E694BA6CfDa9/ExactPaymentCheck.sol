// SPDX-License-Identifier: MIT
// Copyright 2023 SolidifyLabs
pragma solidity >=0.8.0 <0.9.0;

import "./Seller.sol";

/**
 * @notice Ensures that the sent value matches the cost exactly.
 */
abstract contract ExactPaymentCheck is Seller {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the payment does not match the supplied cost.
     */
    error WrongPayment(uint256 actual, uint256 expected);

    /**
     * @inheritdoc Seller
     * @dev Checks that the msg.value equals cost and returns input arguments unchanged.
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 cost, bytes memory)
        internal
        view
        virtual
        override
        returns (address, uint64, uint256)
    {
        if (msg.value != cost) {
            revert WrongPayment(msg.value, cost);
        }
        return (to, num, cost);
    }
}
