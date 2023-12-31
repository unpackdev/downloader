// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract Pumpkin is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Pumpkin ", "HEAD")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 365 * 10 ** decimals());
    }
}
