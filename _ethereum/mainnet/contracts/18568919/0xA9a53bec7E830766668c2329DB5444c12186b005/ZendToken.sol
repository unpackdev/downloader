// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity =0.8.21;

import "./ERC20Upgradeable.sol";

contract ZendToken is ERC20Upgradeable {
    uint256 private constant TOTAL_SUPPLY = 100000000e18;

    function __ZendToken_init(address genesis_holder) public initializer {
        __ERC20_init("zkLend Token", "ZEND");

        _mint(genesis_holder, TOTAL_SUPPLY);
    }
}
