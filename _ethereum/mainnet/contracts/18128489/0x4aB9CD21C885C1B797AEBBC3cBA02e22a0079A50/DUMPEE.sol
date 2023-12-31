/*
DUMPEE

https://dumpee.fail
https://t.me/DUMPEEEntrance
https://twitter.com/_DUMPEE_
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract DUMPEE is ERC20 {
    constructor() ERC20("DUMPEE", "DUMPEE") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}