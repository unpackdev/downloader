/**
*
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./ERC20FlashMint.sol";
import "./Ownable.sol";

/// @custom:security-contact judgementdayt1000@proton.me
contract T1000 is ERC20, ERC20Burnable, ERC20Permit, ERC20FlashMint, Ownable {
    constructor(address initialOwner)
        ERC20("T1000", "T1000")
        ERC20Permit("T1000")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 29081997000000 * 10 ** decimals());
    }
}
