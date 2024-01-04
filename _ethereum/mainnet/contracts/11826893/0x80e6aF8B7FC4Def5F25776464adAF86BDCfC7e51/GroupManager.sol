// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./SafeMath.sol";

contract GroupManager {
    using SafeMath for uint256;

    struct Group {
        address owner;
        bytes metadata;
    }

    Group[] public groups;

    event GroupCreated(address indexed creator, uint256 indexed groupId, bytes indexed metadata);
    event GroupMetadataChanged(uint256 indexed groupId, bytes indexed metadata);
    event GroupOwnerChanged(uint256 indexed groupId, address indexed oldOwner, address indexed newOwner);

    function groupCount() external view returns (uint256) {
        return groups.length;
    }

    function groupOwner(uint256 _groupId) external view returns (address) {
        return groups[_groupId].owner;
    }

    function groupMetadata(uint256 _groupId) external view returns (string memory) {
        return string(groups[_groupId].metadata);
    }

    function createGroup(address _owner, bytes calldata _metadata) external returns (uint256 groupId) {
        Group memory newGroup = Group(_owner, _metadata);
        groups.push(newGroup);
        emit GroupCreated(_owner, groups.length.sub(1), _metadata);

        return groups.length.sub(1);
    }

    function changeGroupOwner(uint256 _groupId, address _newOwner) external {
        require(msg.sender == groups[_groupId].owner, "GroupManager/insufficient-permissions");
        address oldOwner = groups[_groupId].owner;
        groups[_groupId].owner = _newOwner;
        emit GroupOwnerChanged(_groupId, oldOwner, _newOwner);
    }

    function changeGroupMetadata(uint256 _groupId, bytes calldata _metadata) external {
        require(msg.sender == groups[_groupId].owner, "GroupManager/insufficient-permissions");
        groups[_groupId].metadata = _metadata;
        emit GroupMetadataChanged(_groupId, _metadata);
    }
}
