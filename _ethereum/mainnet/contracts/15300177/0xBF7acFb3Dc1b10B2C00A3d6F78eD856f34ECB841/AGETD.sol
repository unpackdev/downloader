// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AGETD is ERC20 {
    constructor(address to, uint256 initialSupply) ERC20("AGET DAO Token", "AGETD") {
        _mint(to, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 5;
    }
}