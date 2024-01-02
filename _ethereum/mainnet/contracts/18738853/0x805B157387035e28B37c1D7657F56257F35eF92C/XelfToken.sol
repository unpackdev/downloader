//SPDX-License-Identifier: MIT
// XELF.AI Token
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract XelfToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 4000000000 * (10 ** 18); // For example, 10,000 tokens with 18 decimals

    constructor() ERC20('Xelf AI', 'XLF') Ownable(msg.sender) {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "XelfToken: cap exceeded");
        _mint(to, amount);
    }
}

