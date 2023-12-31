
/*
$KIWI | Skyward Aspirations

Soaring Beyond Boundaries
The $KIWI flight is scheduled to soar high on October 11th, 2023.
Something amazing is about to happen.
Don't miss the crypto adventure of a lifetime! 

web: https://kiwitoken.tech/
tg : https://t.me/KiwiOfficialPortal
twt: https://twitter.com/Kiwi_ERC20
*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract KIWI is ERC20 { 
    constructor() ERC20("Kiwi", "KIWI") { 
        _mint(msg.sender, 222_000_000_000 * 10**18);
    }
}