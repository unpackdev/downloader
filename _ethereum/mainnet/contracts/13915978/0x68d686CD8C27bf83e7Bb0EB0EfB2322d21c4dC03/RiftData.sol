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
    function bags(uint256 bagId) external view returns (RiftBag memory);
    function addCharges(uint16 charges, uint256 bagId) external;
    function removeCharges(uint16 charges, uint256 bagId) external;
    function updateLevel(uint16 level, uint256 bagId) external;
    function updateXP(uint64 xp, uint256 bagId) external;
    function addKarma(uint64 k, address holder) external;
    function removeKarma(uint64 k, address holder) external;
    function updateLastChargePurchase(uint64 time, uint256 bagId) external;
    function karma(address holder) external view returns (uint64);
    function karmaTotal() external view returns (uint256);
    function karmaHolders() external view returns (uint256);
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

     function initialize() public initializer {
        __Ownable_init();
     }

    function addRiftController(address addr) external onlyOwner {
        riftControllers[addr] = true;
    }

    function removeRiftController(address addr) external onlyOwner {
        riftControllers[addr] = false;
    }

    modifier onlyRiftController() {
        require(riftControllers[msg.sender], "NO!");
        _;
    }

    function bags(uint256 bagId) external view override returns (RiftBag memory) {
        return _bags[bagId];
    }

    function getBags(uint256[] calldata bagIds) external view returns (RiftBag[] memory output) {
        for(uint256 i = 0; i < bagIds.length; i++) {
            output[i] = _bags[bagIds[i]];
        }

        return output;
    }

    function addCharges(uint16 charges, uint256 bagId) external override onlyRiftController {
        _bags[bagId].charges += charges;
    }

    function removeCharges(uint16 charges, uint256 bagId) external override onlyRiftController {
        require(_bags[bagId].charges >= charges, "Not enough charges");
        _bags[bagId].charges -= charges;
        _bags[bagId].chargesUsed += charges;
    }

    function updateLevel(uint16 level, uint256 bagId) external override onlyRiftController {
        _bags[bagId].level = level;
    }

    function updateXP(uint64 xp, uint256 bagId) external override onlyRiftController {
        _bags[bagId].xp = xp;
    }

    function addKarma(uint64 k, address holder) external override onlyRiftController {
        if (karma[holder] == 0) { karmaHolders += 1; }
        karmaTotal += k;
        karma[holder] += k;
    }

    function removeKarma(uint64 k, address holder) external override onlyRiftController {
        k > karma[holder] ? karma[holder] = 0 : karma[holder] -= k;
    }

    function updateLastChargePurchase(uint64 time, uint256 bagId) external override onlyRiftController {
        _bags[bagId].lastChargePurchase = time;
    }
}