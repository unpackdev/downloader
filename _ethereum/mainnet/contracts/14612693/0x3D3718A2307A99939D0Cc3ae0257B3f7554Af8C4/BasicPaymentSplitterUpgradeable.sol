// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// hack: add this import so the compiled ABI is available in hardhat artifacts dir for deployment
import "./PaymentSplitterUpgradeable.sol";

contract BasicPaymentSplitterUpgradeable is PaymentSplitterUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address[] memory payees, uint256[] memory shares_)
        public
        initializer
    {
        __PaymentSplitter_init(payees, shares_);
    }

    uint256[50] private __gap;
}
