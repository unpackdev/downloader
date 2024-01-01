// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract Orgasmus is ERC20 {
    constructor() ERC20("Orgasmus", "ORG") {
        _mint(msg.sender, 1000000000000000 * 10 ** 18);
    }
}