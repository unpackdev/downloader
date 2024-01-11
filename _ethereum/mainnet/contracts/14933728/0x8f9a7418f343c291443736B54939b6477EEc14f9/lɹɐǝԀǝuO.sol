// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract OP2UR is ERC20, ERC20Burnable {
    constructor() ERC20("l\u0279\u0250\u01DD\u0500 \u01DDuO", "(\u25BD)") {
        _mint(msg.sender, 10000111101000 * 10 ** decimals());
    }
}