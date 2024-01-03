// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauserUpgradeable.sol";

contract Token is ERC20PresetMinterPauserUpgradeable {
    function initialize(string memory name, string memory symbol) public override initializer {
        ERC20PresetMinterPauserUpgradeable.initialize(name, symbol);
        _mint(_msgSender(), 1000000000 * (10 ** uint256(decimals())));
    }

    function setName(string memory name_) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "TokenV2: must have admin role to set name");
        _name = name_;
    }
}
