// XǝdǝԀoɹʇs∀
// XԀ∀

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract APX is ERC20 { 
    constructor() ERC20(unicode"XǝdǝԀoɹʇs∀", unicode"XԀ∀") { 
        _mint(msg.sender, 420_690_000_000 * 10**18);
    }
}