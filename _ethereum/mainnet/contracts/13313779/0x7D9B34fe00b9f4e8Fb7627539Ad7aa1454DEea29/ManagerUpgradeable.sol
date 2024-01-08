// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./OwnableUpgradeable.sol";

abstract contract ManagerUpgradeable is OwnableUpgradeable {
    mapping(address => bool) public managers;

    function __Manager_init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        address ownerAddr = owner();
        setManager(ownerAddr);
    }
    modifier onlyManagers() {
        require(managers[msg.sender]);
        _;
    }

    event SetManager(address _manager);
    event RemoveManager(address _manager);

    function setManager(address _manager) public onlyOwner {
        managers[_manager] = true;
        emit SetManager(_manager);
    }

    function removeManager(address _manager) public onlyOwner {
        delete managers[_manager];
        emit RemoveManager(_manager);
    }

}
