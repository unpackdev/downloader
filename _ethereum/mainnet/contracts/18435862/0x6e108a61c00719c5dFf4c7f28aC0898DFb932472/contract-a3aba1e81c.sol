// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract OpiumBird is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("Opium Bird", "BIRD")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 20270000000000 * 10 ** decimals());
    }
}
