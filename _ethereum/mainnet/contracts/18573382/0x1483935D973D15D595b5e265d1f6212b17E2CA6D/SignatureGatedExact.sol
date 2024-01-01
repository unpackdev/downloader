// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import "./CallbackerWithAccessControl.sol";
import "./SignatureGated.sol";

/**
 * @notice Seller handling purchases based on signed allowances.
 */
contract SignatureGatedExact is SignatureGated, CallbackerWithAccessControl {
    /**
     * @notice Thrown if the payment does not match the computed cost.
     */
    error WrongPayment(uint256 actual, uint256 expected);

    constructor(address admin, address steerer, ISellable sellable_)
        CallbackerWithAccessControl(admin, steerer, sellable_)
    {}

    /**
     * @notice Changes set of signers authorised to sign allowances.
     */
    function changeAllowlistSigners(address[] calldata rm, address[] calldata add)
        public
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _changeAllowlistSigners(rm, add);
    }

    /**
     * @notice Interface to perform purchases with signed allowances.
     */
    function purchase(SignedAllowancePurchase[] calldata purchases) public payable virtual override {
        uint256 cost = 0;
        for (uint256 i; i < purchases.length; ++i) {
            cost += purchases[i].signedAllowance.allowance.price * purchases[i].num;
        }
        if (msg.value != cost) {
            revert WrongPayment(msg.value, cost);
        }

        super.purchase(purchases);
    }
}
