// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";

contract KillSwitchToken is ERC20Capped {
    constructor(address _mintTo) ERC20("KillSwitchToken", "KSW") ERC20Capped(200_000_000 ether) {
        ERC20._mint(_mintTo, 200_000_000 ether);
    }
}
