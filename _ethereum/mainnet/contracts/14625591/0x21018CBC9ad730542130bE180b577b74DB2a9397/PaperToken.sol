// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract PaperToken is ERC20Burnable, Ownable {
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply
    ) ERC20(tokenName, tokenSymbol) {
        _mint(msg.sender, initialSupply * (10**decimals()));
    }
}
