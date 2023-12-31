/*

Elon tweet:  x.com/elonmusk/status/1706178349268103182?s=20
TELEGRAM:    t.me/Roman_erc

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract WIFI is ERC20 {
    constructor() ERC20("Anyone feeling late stage empire vibes?", "WIFI") {
        _mint(msg.sender, 100000000 * 10**18);
    }
}