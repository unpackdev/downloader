// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";
import "./Ownable.sol";

contract Nonefakev is ERC20, ERC20Permit, Ownable {
    constructor() ERC20("Nonefakev", "NFV") ERC20Permit("Nonefakev") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
