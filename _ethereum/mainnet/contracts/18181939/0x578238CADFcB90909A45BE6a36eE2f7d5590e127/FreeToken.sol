// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./CopyrightToken.sol";

/**
 * @dev FreeToken: Demo ERC20 implementation
 */
contract FreeToken is ERC20, CopyrightToken {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) CopyrightToken("2.0") {
        // mint 10,000 tokens to the contract deployer
        _mint(_msgSender(), 10000 * 10 ** 18);
    }
}
