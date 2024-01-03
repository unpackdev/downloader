//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract Water is ERC20, Ownable {
    constructor() ERC20("Water", "H2O") {
    }

    function mint(address receiver, uint256 amount) public onlyOwner {
        _mint(receiver, amount);
    }
}