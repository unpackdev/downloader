//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utilities.sol";

contract Adminable is Utilities {

    mapping(address => bool) private admins;

    function addAdmin(address _address) external onlyOwner {
        require(_address.code.length > 0, "must be a contract");
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        for(uint256 i = 0; i < len; i++) {
            require(_addresses[i].code.length > 0, "must be a contract");
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        for(uint256 i = 0; i < len; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }
}