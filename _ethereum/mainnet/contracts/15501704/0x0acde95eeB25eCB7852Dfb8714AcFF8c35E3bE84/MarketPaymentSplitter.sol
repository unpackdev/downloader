// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PaymentSplitterUpgradeable.sol";
import "./IPaymentSplitterInitializer.sol";

contract MarketPaymentSplitter is
    IPaymentSplitterInitializer,
    PaymentSplitterUpgradeable
{
    function initialize(address[] memory payees, uint256[] memory shares_)
        public
        override
        initializer
    {
        __PaymentSplitter_init(payees, shares_);
    }
}
