// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract Mackerel is ERC20, ERC20Permit {
    constructor() ERC20("Mackerel", "MACKS") ERC20Permit("Mackerel") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}
