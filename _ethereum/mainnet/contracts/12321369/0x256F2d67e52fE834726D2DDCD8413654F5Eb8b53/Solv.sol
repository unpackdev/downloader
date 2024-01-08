// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC20.sol";

contract SOLV is ERC20 {

    constructor(address minter) ERC20("Solv", "SOLV") {
        uint256 amount = 100000000 * 1e18; //decimals 18
        _mint(minter, amount);
    }
}
