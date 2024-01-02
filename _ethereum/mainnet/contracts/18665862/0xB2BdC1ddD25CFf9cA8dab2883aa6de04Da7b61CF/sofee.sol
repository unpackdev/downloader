// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

contract Sofee is ERC20 {
    constructor() ERC20("Sofee", "Sofee") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}
