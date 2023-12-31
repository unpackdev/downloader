// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract HelloWorld is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("HelloWorld", "444")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
