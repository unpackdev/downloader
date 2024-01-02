// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract GlobalToken is ERC20 {
    constructor() ERC20("Global Token", "GBL") {
        _mint(msg.sender, 17900000 * 10 ** decimals());
    }
}
