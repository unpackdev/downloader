// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./RiftData.sol";

interface IRift {
    function riftLevel() external view returns (uint32);
    function setupNewBag(uint256 bagId) external;
    function useCharge(uint16 amount, uint256 bagId, address from) external;
    function bags(uint256 bagId) external view returns (RiftBag memory);
    function awardXP(uint32 bagId, uint16 xp) external;
    function isBagHolder(uint256 bagId, address owner) external;
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

interface IRiftBurnable {
    function burnObject(uint256 tokenId) external view returns (BurnableObject memory);
}

interface IMana {
    function ccMintTo(address recipient, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}