// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Calcium2 is ERC20 {
    constructor() ERC20("CAL2.0", "Calcium2.0") {
        uint256 tokenSupply = 420690000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
