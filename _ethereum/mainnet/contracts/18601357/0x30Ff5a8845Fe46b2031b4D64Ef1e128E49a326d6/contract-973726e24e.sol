// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

contract YetiToken is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("YetiToken", "YETI")
        ERC20Permit("YetiToken")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 150000000000 * 10 ** decimals());
    }
}
