// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract BAMS is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("BAMS", "BAMS") ERC20Permit("BAMS") {
        //1.000.000.000
        _mint(msg.sender, 1_000_000_000 ether);
    }
}