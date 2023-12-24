// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract Memeow is ERC20, Ownable, ERC20Permit {
    constructor(address initialOwner)
        ERC20("Memeow", "MMW")
        Ownable(initialOwner)
        ERC20Permit("Memeow")
    {
        _mint(msg.sender, 69042020242024 * 10 ** decimals());
    }
}
