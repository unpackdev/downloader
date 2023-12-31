// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Maxim is ERC20, ERC20Burnable, Ownable {
    
    uint256 private constant _totalSupply = 1e12 * 1e18; // 1 trillion tokens with 18 decimals

    constructor() ERC20("Maxim", "MAXIM") {
        _mint(msg.sender, _totalSupply);
    }
}