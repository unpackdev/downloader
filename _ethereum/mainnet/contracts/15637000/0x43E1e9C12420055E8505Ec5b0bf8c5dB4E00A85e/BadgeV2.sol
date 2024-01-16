// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Badge.sol";

contract BadgeV2 is Badge {
    mapping(uint256 => bool) public isBadgeLockedMap;
    event BadgeBurned(
        uint256 indexed badgeId,
        address indexed from,
        uint256 amount
    );
    event BadgeIpfsUpdated(
        address indexed publisher,
        uint256 indexed badgeId,
        string newIpfsHash
    );
    event BadgeIpfsLocked(
        address indexed publisher,
        uint256 indexed badgeId
    );

    uint256 internal constant PUBLISHER_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 internal constant PUBLISHER_OFFSET = 256 - 160;
    uint256 internal constant PUBLISHER_MASK =  0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF << PUBLISHER_OFFSET;

    function updateBadgeIpfsHash(uint256 badgeId, string memory newIpfsHash) public virtual {
        address sender = msg.sender;
        address publisher = address(uint160((badgeId & PUBLISHER_MASK) >> PUBLISHER_OFFSET));
        require(msg.sender == publisher, "updateBadgeIpfsHash: Unauthorized");
        require(isBadgeLockedMap[badgeId] != true, "updateBadgeIpfsHash: locked");
        ipfsHashMap[badgeId] = newIpfsHash;
        emit BadgeIpfsUpdated(sender, badgeId, newIpfsHash);
    }

    function lockBadgeIpfsHash(uint256 badgeId) public virtual {
        address sender = msg.sender;
        address publisher = address(uint160((badgeId & PUBLISHER_MASK) >>
                 PUBLISHER_OFFSET));
        require(msg.sender == publisher, "lockBadgeIpfsHash: Unauthorized");
        isBadgeLockedMap[badgeId] = true;
        emit BadgeIpfsLocked(sender, badgeId);
    }

    function burnBatch(
        address from,
        uint256[] memory badgeIds,
        uint256[] memory amounts
    ) public virtual onlyRole(MINTER_ROLE) {
        _burnBatch(from, badgeIds, amounts);
        for (uint256 i=0; i<badgeIds.length; i++) {
            emit BadgeBurned(badgeIds[i], from, amounts[i]);
        }
    }

    function getVersion() public pure virtual returns (string memory) {
        return "2.0.0";
    }
}