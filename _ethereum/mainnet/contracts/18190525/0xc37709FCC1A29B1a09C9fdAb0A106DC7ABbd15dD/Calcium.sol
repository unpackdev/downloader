// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Calcium is ERC20 {
    constructor() ERC20("CAL", "Calcium") {
        uint256 tokenSupply = 420690000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
