// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

abstract contract Ownable {

    error Unauthorized();
    error ZeroAddress();

    event OwnerSet(address indexed newOwner_);
    event PendingOwnerSet(address indexed pendingOwner_);

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    function setPendingOwner(address pendingOwner_) external onlyOwner {
        _setPendingOwner(pendingOwner_);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert Unauthorized();

        _setPendingOwner(address(0));
        _setOwner(msg.sender);
    }

    function _setOwner(address owner_) internal {
        if (owner_ == address(0)) revert ZeroAddress();

        emit OwnerSet(owner = owner_);
    }

    function _setPendingOwner(address pendingOwner_) internal {
        emit PendingOwnerSet(pendingOwner = pendingOwner_);
    }

}
