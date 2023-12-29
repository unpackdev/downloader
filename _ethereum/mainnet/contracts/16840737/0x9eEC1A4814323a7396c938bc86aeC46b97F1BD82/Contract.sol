// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Toku is ERC20, ERC20Burnable, Ownable {
    constructor(string memory _name, string memory _symbol, uint256 supply) ERC20(_name, _symbol) {
        _mint(msg.sender, supply * 10 ** decimals());
    }
}