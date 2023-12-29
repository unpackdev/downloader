// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract POW is ERC20Burnable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address receiver
    ) ERC20(name, symbol) {
        _mint(receiver, initialSupply);
    }
}
