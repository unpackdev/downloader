// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

/// @custom:security-contact 0x746C@skiff.com
contract InuFlame is ERC20, ERC20Permit, Ownable {
    constructor(address _address) ERC20("InuFlame", "FLAME") ERC20Permit("MyToken") Ownable(msg.sender) {
        _mint(_address, 42000000000 * 10 ** decimals());
    }
}