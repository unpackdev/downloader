// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract ParityCardToken is ERC20, ERC20Permit {
    constructor() ERC20("ParityCard Token", "PTYCD") ERC20Permit("ParityCard Token") {
        _mint(msg.sender, 1*10**9 * 10**18);
    }
}
