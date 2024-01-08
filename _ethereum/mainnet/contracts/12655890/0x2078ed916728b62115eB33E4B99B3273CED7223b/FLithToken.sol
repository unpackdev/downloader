// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC20.sol";

/**
 * @title FLithToken
 *
 * @dev A minimal ERC20 token contract for the future lithium token.
 */
contract FLithToken is ERC20("Future Lithium", "fLITH") {
    uint256 private constant TOTAL_SUPPLY = 28000000e18;

    constructor(address genesis_holder) {
        require(genesis_holder != address(0), "FLithToken: zero address");
        _mint(genesis_holder, TOTAL_SUPPLY);
    }
}
