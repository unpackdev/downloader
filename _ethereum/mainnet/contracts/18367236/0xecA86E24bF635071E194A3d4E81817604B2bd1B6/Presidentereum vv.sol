/*
Presidentereum

A Time for Greatness
Strengthening community governance via innovative blockchain solutions.

By merging the foundational principles of leadership and community with the transformative power of decentralized technology, 
PTM offers a new paradigm for collaborative decision-making and governance.

https://presidentereum.tech/
https://t.me/PresidentereumPortal
https://twitter.com/Presidentereum
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract Presidentereum is ERC20 { 
    constructor() ERC20("Presidentereum", "PTM") { 
        _mint(msg.sender, 47_000_000 * 10**18);
    }
}