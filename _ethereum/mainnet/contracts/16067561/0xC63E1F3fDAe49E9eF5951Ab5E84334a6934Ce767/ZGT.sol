// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

/// @custom:security-contact info@zkfinance.app
contract ZGT is ERC20 {
    constructor() ERC20("zkFinance Governance Token", "ZGT") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}