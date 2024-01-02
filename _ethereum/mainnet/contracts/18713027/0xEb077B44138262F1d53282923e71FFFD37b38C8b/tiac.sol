// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract CelestiaC is ERC20, ERC20Permit {
    constructor() ERC20("Celestia Classic", "TIAC") ERC20Permit("Celestia Classic") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
