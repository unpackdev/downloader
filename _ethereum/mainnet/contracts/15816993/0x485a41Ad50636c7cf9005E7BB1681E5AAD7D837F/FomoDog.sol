// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./Ownable.sol";

contract FomoDog is ERC20, ERC20Permit, Ownable {
    constructor() ERC20("FomoDog", "FOG") ERC20Permit("FomoDog") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
}
