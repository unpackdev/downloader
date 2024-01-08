// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract REIN is ERC20 {
    constructor() ERC20("REIN", "REIN") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
}