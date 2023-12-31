// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract XBOTTECH is ERC20 {
    constructor() ERC20("XBOT", "XBT") {
        _mint(msg.sender, 100_000_000 * 10**18);
    }
}