// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

contract Holloween is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("Holloween", "AHE")
        ERC20Permit("Holloween")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 202300000000000 * 10 ** decimals());
    }
}
