// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import "./Seller.sol";
import "./CallbackerWithAccessControl.sol";
import "./Public.sol";
import "./ExactSettableFixedPrice.sol";
import "./InternallyPriced.sol";

import "./SettablePerAddressLimited.sol";

/**
 * @notice Public seller with a fixed price.
 */
contract PublicLimitedExactFixedPrice is Public, ExactSettableFixedPrice, SettablePerAddressLimited {
    constructor(address admin, address steerer, ISellable sellable_, uint256 price, uint64 maxPerAddress_)
        CallbackerWithAccessControl(admin, steerer, sellable_)
        ExactSettableFixedPrice(price)
    {
        _setMaxPerAddress(maxPerAddress_);
    }

    /**
     * @inheritdoc Seller
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 totalCost, bytes memory data)
        internal
        view
        virtual
        override(InternallyPriced, ExactInternallyPriced, PerAddressLimited)
        returns (address, uint64, uint256)
    {
        (to, num, totalCost) = ExactInternallyPriced._checkAndModifyPurchase(to, num, totalCost, data);
        (to, num, totalCost) = PerAddressLimited._checkAndModifyPurchase(to, num, totalCost, data);
        return (to, num, totalCost);
    }

    /**
     * @inheritdoc Seller
     */
    function _beforePurchase(address to, uint64 num, uint256 totalCost, bytes memory data)
        internal
        virtual
        override(Seller, PerAddressLimited)
    {
        Seller._beforePurchase(to, num, totalCost, data);
        PerAddressLimited._beforePurchase(to, num, totalCost, data);
    }
}
