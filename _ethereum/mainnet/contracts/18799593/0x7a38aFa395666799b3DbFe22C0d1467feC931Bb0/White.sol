// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract White is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Scramble White", "WHITE") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
