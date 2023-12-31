// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Calcium3 is ERC20 {
    constructor() ERC20("CAL3", "Calcium3.0") {
        uint256 tokenSupply = 420690000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
