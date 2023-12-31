// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20PermitUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract BIFI is ERC20Upgradeable, ERC20PermitUpgradeable {
    
    function initialize(address _treasury) external initializer {
        __ERC20_init("mooTest", "mooTest");
        __ERC20Permit_init("Beefy");
        _mint(_treasury, 80_000 ether);
    }
}