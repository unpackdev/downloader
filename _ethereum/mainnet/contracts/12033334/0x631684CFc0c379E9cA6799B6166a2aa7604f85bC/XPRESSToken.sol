// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract XPRESSToken is ERC20, ERC20Burnable {
    constructor() ERC20("XPRESS Token", "XPRESS") {
        _mint(msg.sender, 10000000 * (10**uint256(decimals())));
    }
}
