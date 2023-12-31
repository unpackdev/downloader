// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract LockheedMartinInu is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("Lockheed Martin Inu", "LMI")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 100000000000000000 * 10 ** decimals());
    }
}
