//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

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

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not an admin");
        _;
    }

    uint256[49] private __gap;
}
