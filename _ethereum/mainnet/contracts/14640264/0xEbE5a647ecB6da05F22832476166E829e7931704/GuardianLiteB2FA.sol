// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILockERC721.sol";

contract GuardianLiteB2FA {
    ILockERC721 public immutable LOCKABLE;

    mapping(address => address) public guardians;

    event GuardianSet(address indexed guardian, address indexed user);
    event GuardianRenounce(address indexed guardian, address indexed user);

    constructor() {
        LOCKABLE = ILockERC721(address(this));
    }

    function setGuardian(address _guardian) external {
        require(guardians[msg.sender] == address(0), "Guardian set");
        require(msg.sender != _guardian, "Guardian must be a different wallet");
        guardians[msg.sender] = _guardian;
        emit GuardianSet(_guardian, msg.sender);
    }

    function renounce(address _tokenOwner) external {
        require(guardians[_tokenOwner] == msg.sender, "!guardian");
        guardians[_tokenOwner] = address(0);
        emit GuardianRenounce(msg.sender, _tokenOwner);
    }

    function lockMany(uint256[] calldata _tokenIds) external {
        address owner = LOCKABLE.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(LOCKABLE.ownerOf(_tokenIds[i]) == owner, "!owner");
            LOCKABLE.lockId(_tokenIds[i]);
        }
    }

    function unlockMany(uint256[] calldata _tokenIds) external {
        address owner = LOCKABLE.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(LOCKABLE.ownerOf(_tokenIds[i]) == owner, "!owner");
            LOCKABLE.unlockId(_tokenIds[i]);
        }
    }

    function unlockManyAndTransfer(
        uint256[] calldata _tokenIds,
        address _recipient
    ) external {
        address owner = LOCKABLE.ownerOf(_tokenIds[0]);
        require(guardians[owner] == msg.sender, "!guardian");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(LOCKABLE.ownerOf(_tokenIds[i]) == owner, "!owner");
            LOCKABLE.unlockId(_tokenIds[i]);
            LOCKABLE.safeTransferFrom(owner, _recipient, _tokenIds[i]);
        }
    }
}
