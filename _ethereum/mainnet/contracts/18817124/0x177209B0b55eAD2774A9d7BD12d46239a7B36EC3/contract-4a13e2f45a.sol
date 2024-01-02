// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract Hiatus is ERC20 {
    constructor() ERC20("hiatus", "hiatus") {
        _mint(msg.sender, 404000000000000 * 10 ** decimals());
    }
}
