// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import "./Types.sol";
import "./IAlbaDelegate.sol";
import "./IPaymentSplitter.sol";

library Splitters {
    error InvalidConfiguration();

    /**
     * Setup the sales splitters.
     * @dev We expect an array of length 1 for a single user (if there's no Alba fee). This is less efficient
     * than just using the artist's address rather than a splitter, but it provides consistent UX for claiming.
     */

    function setupPaymentSplitters(PaymentConfig calldata conf, IAlbaDelegate albaDelegate)
        public
        returns (IPaymentSplitter, IPaymentSplitter)
    {
        if (conf.primaryPayees.length == 0 || conf.primaryPayees.length != conf.primaryShareBasisPoints.length) {
            revert InvalidConfiguration();
        }
        IPaymentSplitter paymentSplitter;
        IPaymentSplitter paymentSplitterRoyalties;

        address primary = albaDelegate.paymentSplitterFactory().deploy(conf.primaryPayees, conf.primaryShareBasisPoints);
        paymentSplitter = IPaymentSplitter(primary);

        // Only deploy a contract for secondary payments if there are secondary payees.
        if (conf.secondaryPayees.length > 0) {
            if (conf.secondaryPayees.length != conf.secondaryShareBasisPoints.length) {
                revert InvalidConfiguration();
            }

            address secondary =
                albaDelegate.paymentSplitterFactory().deploy(conf.secondaryPayees, conf.secondaryShareBasisPoints);
            paymentSplitterRoyalties = IPaymentSplitter(secondary);
        }

        return (paymentSplitter, paymentSplitterRoyalties);
    }
}
