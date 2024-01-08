// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Ecoin is ERC20("Ecoin chain token", "ECOIN"), Ownable {
    constructor() {
        _mint(msg.sender, 3800000000 * 1e18);
    }
}
