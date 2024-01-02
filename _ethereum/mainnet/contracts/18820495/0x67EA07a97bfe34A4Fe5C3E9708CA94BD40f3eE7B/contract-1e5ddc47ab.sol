// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

contract BluePill is ERC20, ERC20Permit, Ownable {
    constructor()
        ERC20("BluePill", "BPILL")
        ERC20Permit("BluePill")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 10130370858 * 10 ** decimals());
    }
}
