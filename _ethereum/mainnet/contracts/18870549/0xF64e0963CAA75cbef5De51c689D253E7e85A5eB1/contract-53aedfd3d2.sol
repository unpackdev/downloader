// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract MoyeMoye is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("Moye Moye", "MOYE")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
}
