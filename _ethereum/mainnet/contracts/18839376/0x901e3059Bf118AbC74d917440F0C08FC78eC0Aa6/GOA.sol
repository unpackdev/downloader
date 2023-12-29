// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract GOA is ERC20, ERC20Permit {
    constructor(address _treasury) ERC20("GOAT", "GOA") ERC20Permit("GOAT") {
        _mint(_treasury, 1_000_000 ether);
    }
}
