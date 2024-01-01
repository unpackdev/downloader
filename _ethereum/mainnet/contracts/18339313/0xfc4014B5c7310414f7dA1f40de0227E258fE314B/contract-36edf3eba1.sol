// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract WBTCERC is ERC20 {
    constructor() ERC20("WBTC/ETH/SHIB", "Bitcoin") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}
