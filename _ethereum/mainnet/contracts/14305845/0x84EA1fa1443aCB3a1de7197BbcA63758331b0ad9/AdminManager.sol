//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Initializable.sol";

contract AdminManagerUpgradable is Initializable {
    mapping(address => bool) private _admins;

    function __AdminManager_init() internal onlyInitializing {
        _admins[msg.sender] = true;
    }

    function setAdminPermissions(address account, bool enable)
        external
        onlyAdmin
    {
        _admins[account] = enable;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Not an admin");
        _;
    }

    uint256[49] private __gap;
}
