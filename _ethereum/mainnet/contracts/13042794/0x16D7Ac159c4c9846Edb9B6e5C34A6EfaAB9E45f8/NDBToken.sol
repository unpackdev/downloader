// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "./ERC20.sol";

contract NDBToken is ERC20 {
    constructor () ERC20("NDB Token", "ndb") public {
        // has 4 decimals
         _setupDecimals(4);
        // mint 918 000 000.0000 tokens for deployer
        _mint(msg.sender, 9180000000000);
    }
}
