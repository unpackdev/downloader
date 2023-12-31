// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract HAUS is ERC20 {
    constructor() ERC20("HAUS Lifestyle Token", "HAUS") {
                _mint(msg.sender, 69690 * (10 ** uint256(decimals())));
    }
}