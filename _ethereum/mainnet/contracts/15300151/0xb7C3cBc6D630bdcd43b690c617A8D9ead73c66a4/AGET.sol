// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AGET is ERC20 {
    constructor(address to, uint256 initialSupply) ERC20("ACE Global Exchange Token", "AGET") {
        _mint(to, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 5;
    }
}