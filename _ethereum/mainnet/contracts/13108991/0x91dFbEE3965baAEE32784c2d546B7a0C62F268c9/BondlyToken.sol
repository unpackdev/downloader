// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract BondlyToken is ERC20 {
    uint256 public cap = 983620759 ether;

    constructor () ERC20("Bondly", "BONDLY") public {
        super._mint(msg.sender, cap);
    }
}