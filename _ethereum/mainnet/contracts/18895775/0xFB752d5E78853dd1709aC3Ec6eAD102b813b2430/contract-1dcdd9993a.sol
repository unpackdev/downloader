// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

contract Rihno is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("rihno", "Rihno")
        ERC20Permit("rihno")
        Ownable(initialOwner)
    {
        _mint(initialOwner, 1000000000 * 10 ** decimals());
    }
}
