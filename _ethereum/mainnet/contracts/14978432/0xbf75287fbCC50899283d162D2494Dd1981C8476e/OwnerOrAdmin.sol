// SPDX-License-Identifier: AGPL-3.0

import "./Ownable.sol";

pragma solidity ^0.8.0;

contract OwnerOrAdmin is Ownable {

    mapping(address => bool) public admins;

    function _isOwnerOrAdmin() private view {
        require(
            owner() == msg.sender || admins[msg.sender],
            "OwnerOrAdmin: unauthorized"
        );
    }

    modifier onlyOwnerOrAdmin() {
        _isOwnerOrAdmin();
        _;
    }

    function setAdmin(address _address, bool _hasAccess) external onlyOwner {
        admins[_address] = _hasAccess;
    }

}
