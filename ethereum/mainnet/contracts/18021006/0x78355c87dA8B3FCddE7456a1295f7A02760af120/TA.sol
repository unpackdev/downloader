// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract TechnicalAnalysis is ERC20 {
    constructor() ERC20("Technical Analysis", "TA") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}