// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./RiftData.sol";

interface IRift {
    function riftLevel() external view returns (uint32);
    function useCharge(uint16 amount, uint256 bagId, address from) external;
    function isBagHolder(uint256 bagId, address owner) external;
    function addPower(uint256 power) external;
}

struct BagProgress {
    uint32 lastCompletedStep;
    bool completedQuest;
}

struct BurnableObject {
    uint64 power;
    uint32 mana;
    uint16 xp;
}

struct ChargeData {
    uint64 chargesPurchased;
    uint64 chargesUsed;
    uint128 lastPurchase;
}

struct RiftBagInfo {
    uint64 charges;
    uint64 chargesUsed;
    uint64 chargesPurchased;
    uint128 lastChargePurchased;
    uint256 xp;
    uint256 level;
}

interface IRiftBurnable {
    function burnObject(uint256 tokenId) external view returns (BurnableObject memory);
}

interface IMana {
    function ccMintTo(address recipient, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}