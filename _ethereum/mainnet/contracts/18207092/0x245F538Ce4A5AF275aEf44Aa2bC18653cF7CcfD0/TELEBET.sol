/*

https://t.me/TelebetOfficialPortal
https://telebet.cc

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract TELEBET is ERC20 {
    constructor() ERC20("Telebet", "TELEBET") {
        _mint(msg.sender, 10_000_000_000 * 10**18);
    }
}