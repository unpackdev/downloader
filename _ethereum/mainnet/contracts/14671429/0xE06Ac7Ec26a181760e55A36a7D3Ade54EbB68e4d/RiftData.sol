/*

 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀      ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌
▐░▌       ▐░▌     ▐░▌     ▐░▌               ▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌
▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄      ▐░▌          ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌
▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌     ▐░▌          ▐░▌       ▐░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌
▐░█▀▀▀▀█░█▀▀      ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀      ▐░▌          ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀█░▌     ▐░▌     ▐░█▀▀▀▀▀▀▀█░▌
▐░▌     ▐░▌       ▐░▌     ▐░▌               ▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌
▐░▌      ▐░▌  ▄▄▄▄█░█▄▄▄▄ ▐░▌               ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌
▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌               ▐░▌          ▐░░░░░░░░░░▌ ▐░▌       ▐░▌     ▐░▌     ▐░▌       ▐░▌
 ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀                 ▀            ▀▀▀▀▀▀▀▀▀▀   ▀         ▀       ▀       ▀         ▀ 
     by chris and tony                                                                                                       
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

struct RiftBag {
        uint16 charges;
        uint32 chargesUsed;
        uint16 level;
        uint64 xp;
        uint64 lastChargePurchase;
    }

interface IRiftData {
    function updateXP(uint256 xp, uint256 bagId) external;
    function addKarma(uint64 k, address holder) external;
    function removeKarma(uint64 k, address holder) external;
    function karma(address holder) external view returns (uint64);
    function karmaTotal() external view returns (uint256);
    function karmaHolders() external view returns (uint256);
    function addXP(uint256 xp, uint256 bagId) external;
    function getLevel(uint256 bagId) external view returns (uint256);
    function xpMap(uint256 bagId) external view returns (uint256);
}

/*
    Logic free storage of Rift Data. 
    The intent of this storage is twofold:
    1. The data manipulation performed by the Rift is novel (especially to the authors), 
        and this store acts as a failsafe in case a new Rift contract needs to be deployed.
    2. The authors' intent is to grant control of this data to more controllers (a DAO, L2 rollup, etc).
*/
contract RiftData is IRiftData, OwnableUpgradeable {
    mapping(address => bool) public riftControllers;

    uint256 public karmaTotal;
    uint256 public karmaHolders;

    mapping(uint256 => RiftBag) internal _bags;
    mapping(address => uint64) public karma;
    mapping(address => bool) public xpControllers;
    mapping(uint256 => uint256) public xpMap;

     function initialize() public initializer {
        // __Ownable_init();
     }

    function addRiftController(address addr) external onlyOwner {
        riftControllers[addr] = true;
    }

    function removeRiftController(address addr) external onlyOwner {
        riftControllers[addr] = false;
    }

    function addXPController(address addr) external onlyOwner {
        xpControllers[addr] = true;
    }

    function removeXPController(address addr) external onlyOwner {
        xpControllers[addr] = false;
    }

    modifier onlyRiftController() {
        require(riftControllers[msg.sender], "NOT RIFTCONTROLLER!");
        _;
    }

    modifier onlyXPController() {
        require(xpControllers[msg.sender], "NOT XPCONTROLLER!");
        _;
    }

    function updateXP(uint256 xp, uint256 bagId) external override onlyRiftController {
        xpMap[bagId] = xp;
    }

    function addXP(uint256 xp, uint256 bagId) external override onlyXPController {
        xpMap[bagId] += xp;
    }

    function addKarma(uint64 k, address holder) external override onlyRiftController {
        if (karma[holder] == 0) { karmaHolders += 1; }
        karmaTotal += k;
        karma[holder] += k;
    }

    function removeKarma(uint64 k, address holder) external override onlyRiftController {
        k > karma[holder] ? karma[holder] = 0 : karma[holder] -= k;
    }

    function getLevel(uint256 bagId) external override view returns (uint256) {
        uint256 _xp = xpMap[bagId];
        if (_xp < 65) return 1;
        else if (_xp < 70) return 2;
        else {
            return 1 + (sqrt(625+75*_xp)-25)/50; // roughly 15% increase xp per level
        }
    }

    // migrates xp from old system to new
    function migrateXP(uint256[] memory bagIds) external onlyOwner {
        for (uint i=0; i < bagIds.length; i++) {
             xpMap[bagIds[i]] += _bags[bagIds[i]].xp + (_bags[bagIds[i]].level * 125);
        }
    }
}

/// @notice Calculates the square root of x, rounding down.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as an uint256.
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // Calculate the square root of the perfect square of a power of two that is the closest to x.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 0x100000000000000000000000000000000) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 0x10000000000000000) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 0x100000000) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 0x10000) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 0x100) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 0x10) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 0x8) {
        result <<= 1;
    }

    // The operations can never overflow because the result is max 2^127 when it enters this block.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
    }
}