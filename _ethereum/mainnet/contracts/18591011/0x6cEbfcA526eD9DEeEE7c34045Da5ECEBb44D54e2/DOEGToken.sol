// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract DOEGToken is ERC20, ERC20Permit {
    constructor() ERC20("DOEG Token", "DOEG") ERC20Permit("DOEG Token") {
        _mint(msg.sender, 50_000_000 * 10 ** decimals());
    }
}
