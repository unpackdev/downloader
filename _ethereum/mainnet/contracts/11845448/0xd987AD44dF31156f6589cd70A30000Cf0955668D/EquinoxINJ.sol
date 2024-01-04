// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./ERC20.sol";

contract EquinoxINJ is ERC20 {
    constructor() public ERC20("Equinox Injective Token", "eINJ") {
        _mint(msg.sender, 1000**12 * 1 ether);
    }
}
