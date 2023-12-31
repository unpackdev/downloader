// https://astrobobox.xyz/
// https://t.me/AstroBoboXPortal
// https://twitter.com/AstroBoboX_
// Bobo's got your back, bear or bull, with ABX, your wallet's always full!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract AstroBoboX is ERC20 { 
    constructor() ERC20("AstroBoboX", "ABX") { 
        _mint(msg.sender, 4_206_900_000 * 10**18);
    }
}