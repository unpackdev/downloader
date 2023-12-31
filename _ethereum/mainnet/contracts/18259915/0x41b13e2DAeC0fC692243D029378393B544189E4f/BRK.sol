// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract BRK is ERC20 {
    //max supply 1B
    uint256 public maxSupply = 1000000000 * 10 ** decimals();

    constructor(address owner) ERC20("BRK.A+B", "BRK.A+B") {
        _mint(owner, maxSupply);
    }
}