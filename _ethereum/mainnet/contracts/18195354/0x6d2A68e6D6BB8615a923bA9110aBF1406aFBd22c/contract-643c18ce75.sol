// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract BOOTSBOX is ERC20 {
    constructor() ERC20("BOOTS BOX", "BOOTS") {
        _mint(msg.sender, 7777777777777 * 10 ** decimals());
    }
}
