//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./console.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Bomb is ERC20, ERC20Burnable {
    constructor(uint256 initialSupply) ERC20("Osama Bin Santa", "BOMB") {
        _mint(msg.sender, initialSupply);
    }
}
