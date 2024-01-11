//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./OwnableUpgradeable.sol";
import "./IAdmins.sol";
import "./IAdminsController.sol";

contract AdminsControllerUpgradeable is OwnableUpgradeable, IAdminsController {
    IAdmins private _admins;

    function __AdminController_init(IAdmins admins) internal onlyInitializing {
        _admins = admins;
        __Ownable_init();
    }

    function changeAdmins(IAdmins _newAdmins) external override onlyAdmins {
        _admins = _newAdmins;
    }

    modifier onlyAdmins() {
        require(_admins.isAdmin(msg.sender), "Only authorised");
        _;
    }
}
