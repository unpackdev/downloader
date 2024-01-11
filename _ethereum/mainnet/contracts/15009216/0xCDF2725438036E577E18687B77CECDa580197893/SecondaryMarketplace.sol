//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC2981.sol";

import "./Marketplace.sol";


/**
 * Abstract base contract for secondary marketplaces.
 */
abstract contract SecondaryMarketplace is Marketplace {
    /*********/
    /* Types */
    /*********/

    /**
     * Constant used for representing the maximum value of a uint16 type.
     */
    uint16 public constant UINT16_MAX_VALUE = 65535;

    /**********************/
    /* Internal functions */
    /**********************/

    /**
     * Returns the royalty numerator by extracting it from the collection.
     *
     * @param message The transaction message.
     * @return The royalty numerator.
     */
    function _getRoyaltyNumerator(TransactionMessage calldata message)
        internal
        view
        override
        returns (uint16)
    {
        // The "royaltyInfo" method can be used for calculating a royalty
        // amount by passing in a payment, however since we pass our internal
        // denominator as the payment, the returned royalty amount will
        // represent the collection's royalty nominator in relation to our
        // internal denominator. Therefore we can safely compare the resulting
        // royalty nominator with our configured maximum royalty nominator.
        (, uint256 royaltyNumerator) = ERC2981(
            message.collection
        ).royaltyInfo(
            message.tokenId,
            _getDenominator()
        );

        // Making sure the returned royalty numerator is not bigger than the
        // maximum value for a uint16, so we know it's safe to cast the uint256
        // to a uint16.
        require(
          royaltyNumerator <= UINT16_MAX_VALUE,
          "Royalty numerator too high"
        );

        return uint16(royaltyNumerator);
    }

    /**
     * Internal function for transferring the payment for a transaction
     * message.
     *
     * The payment will split according to the following rules:
     * - The commission amount is kept in the contract.
     * - The royalty amount is sent to the creator.
     * - The payment minus the commission amount and the royalty amount is sent
     *   to the seller.
     *
     * @param message The transaction message.
     */
    function _transferPayment(TransactionMessage calldata message)
        internal
        override
    {
        uint256 commissionAmount = (
            message.payment * commissionNumerator()
        ) / _getDenominator();
        (address royaltyReceiver, uint256 royaltyAmount) = ERC2981(
            message.collection
        ).royaltyInfo(
            message.tokenId,
            message.payment
        );
        payable(royaltyReceiver).transfer(royaltyAmount);

        message.seller.transfer(
            message.payment - (commissionAmount + royaltyAmount)
        );
    }
}
