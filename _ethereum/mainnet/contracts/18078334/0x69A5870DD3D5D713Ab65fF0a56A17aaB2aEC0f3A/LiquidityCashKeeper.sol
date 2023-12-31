// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract LiquidityCashKeeper is ERC20 {
    constructor() ERC20("Liquidity Cash Keeper", "LICK") {
        _mint(msg.sender, 100_000_000 * 10**18);
    }
}