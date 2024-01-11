// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract Whitelist is Initializable, OwnableUpgradeable, PausableUpgradeable {
    mapping(address => bool) whitelist;
    mapping(address => bool) managers;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelist(address _address) {
        require(
            isWhitelisted(_address),
            "Not a whitelist token project address"
        );
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender], "Caller is not the manager");
        _;
    }

    function managerAdd(address _manager) public onlyOwner {
        managers[_manager] = true;
    }

    function managerRemove(address _manager) public onlyOwner {
        managers[_manager] = false;
    }

    function isManager(address _manager) public view returns (bool) {
        return managers[_manager];
    }

    function __Whitelist_init(address creator) public initializer {
        __Pausable_init();
        __Ownable_init();

        transferOwnership(creator);
    }

    function whitelistAdd(address _address) public onlyManager {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function whitelistRemove(address _address) public onlyManager {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function pause() public onlyManager {
        _pause();
    }

    function unpause() public onlyManager {
        _unpause();
    }
}
