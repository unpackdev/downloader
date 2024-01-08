// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract IMToken is ERC20 {
    constructor() ERC20("Idle Mystic Token", "IMT") {
        _mint(msg.sender,  10**9 * 10**18);
    }
}