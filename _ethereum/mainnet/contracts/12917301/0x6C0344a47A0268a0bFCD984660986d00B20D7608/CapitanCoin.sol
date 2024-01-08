// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract CapitanCoin is Context, ERC20, ERC20Detailed {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20Detailed(name, symbol, 18) {
        _mint(_msgSender(), initialSupply);
    }
}