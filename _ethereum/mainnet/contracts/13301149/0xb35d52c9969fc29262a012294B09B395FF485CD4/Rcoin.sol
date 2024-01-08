// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Rcoin is ERC20("Rcoin chain token", "RCOIN"), Ownable {
    constructor() {
        _mint(msg.sender, 10000000 * 1e18);
    }
}
