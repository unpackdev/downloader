// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHive {
    struct Bee {
        address owner;
        uint32 tokenId;
        uint48 since;
        uint8 index;
    }

    struct BeeHive {
        uint32 startedTimestamp;
        uint32 lastCollectedHoneyTimestamp;
        uint32 hiveProtectionBears;
        uint32 lastStolenHoneyTimestamp;
        uint32 collectionAmount;
        uint32 collectionAmountPerBee;
        uint8 successfulAttacks;
        uint8 totalAttacks;
        mapping(uint256 => Bee) bees;
        uint16[] beesArray;
    }

    function addManyToHive(
        address account,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds
    ) external;

    function claimManyFromHive(
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        uint16[] calldata newHiveIds
    ) external;

    function addToWaitingRoom(address account, uint256 tokenId) external;

    function removeFromWaitingRoom(uint256 tokenId, uint256 hiveId) external;

    function setRescueEnabled(bool _enabled) external;

    function setPaused(bool _paused) external;

    function setBeeSince(
        uint256 hiveId,
        uint256 tokenId,
        uint48 since
    ) external;

    function calculateBeeOwed(uint256 hiveId, uint256 tokenId) external view returns (uint256 owed);

    function incSuccessfulAttacks(uint256 hiveId) external;

    function incTotalAttacks(uint256 hiveId) external;

    function setBearAttackData(
        uint256 hiveId,
        uint32 timestamp,
        uint32 protection
    ) external;

    function setKeeperAttackData(
        uint256 hiveId,
        uint32 timestamp,
        uint32 collected,
        uint32 collectedPerBee
    ) external;

    function getLastStolenHoneyTimestamp(uint256 hiveId) external view returns (uint256 lastStolenHoneyTimestamp);

    function getHiveProtectionBears(uint256 hiveId) external view returns (uint256 hiveProtectionBears);

    function isHiveProtectedFromKeepers(uint256 hiveId) external view returns (bool);

    function getHiveOccupancy(uint256 hiveId) external view returns (uint256 occupancy);

    function getBeeSinceTimestamp(uint256 hiveId, uint256 tokenId) external view returns (uint256 since);

    function getBeeTokenId(uint256 hiveId, uint256 index) external view returns (uint256 tokenId);

    function getHiveAge(uint256 hiveId) external view returns (uint32);

    function getHiveSuccessfulAttacks(uint256 hiveId) external view returns (uint8);

    function getWaitingRoomOwner(uint256 tokenId) external view returns (address);

    function resetHive(uint256 hiveId) external;
}
