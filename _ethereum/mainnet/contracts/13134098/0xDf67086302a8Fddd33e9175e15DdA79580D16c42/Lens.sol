// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;
pragma abicoder v2;
import "./console.sol";
import "./IEthMap.sol";


interface IZones {
  function getApproved(uint256 zoneId) external view returns (address);

  function ownerOf(uint256 zoneId) external view returns (address);

  function pendingZoneOwners(uint256 zoneId) external view returns (address);
}


contract Lens {
  IEthMap public constant map = IEthMap(0xB6bbf89c3DbBa20Cb4d5cABAa4A386ACbbAb455e);
  IZones public constant oldZones = IZones(0x7372D7fB769470ff57019404cbf6bC6515E39090);
  IZones public constant mapZones = IZones(0xD509B296183F45D50d49499E7Bf6BF0b1A2bA6d0);

  enum ZoneStatus {
    BASE, // Owned by original contract
    WRAP_PENDING, // Ownership proven to wrapper
    WRAP_READY, // Zone transferred to wrapper
    WRAPPED, // Wrap complete
    MIGRATE_NEEDED, // Wrapped by old wrapper
    MIGRATE_READY, // Approval given to new wrapper
    RECOVERY_NEEDED, // Zone transferred to wrapper without preparation
    RECOVERY_NEEDED_OLD, // Zone transferred to old wrapper without preparation
    WRAP_READY_OLD // Zone transferred to old wrapper
  }

  struct Zone {
    ZoneStatus status;
    address pendingOwner;
    uint id;
    address owner;
    uint sellPrice;
  }

  function tryGetOwner(IZones zones, uint256 zoneId) internal view returns (address) {
    try zones.ownerOf(zoneId) returns (address owner) {
      return owner;
    } catch {
      return address(0);
    }
  }

  function writeStatus(Zone memory zone) internal view {
    zone.pendingOwner = mapZones.pendingZoneOwners(zone.id);
    address owner = tryGetOwner(mapZones, zone.id);
    if (owner != address(0)) { // Zone wrapped
      zone.owner = owner;
      zone.status = ZoneStatus.WRAPPED;
    } else { // NFT not minted yet
      if (zone.pendingOwner == address(0)) { // User transferred the zone without preparing it
        zone.status = ZoneStatus.RECOVERY_NEEDED;
      } else { // Zone was prepared and transferred
        zone.status = ZoneStatus.WRAP_READY;
      }
    }
  }

  function writeStatusOld(Zone memory zone) internal view {
    zone.pendingOwner = oldZones.pendingZoneOwners(zone.id);
    address owner = tryGetOwner(oldZones, zone.id);
    if (owner != address(0)) {// Zone wrapped
      zone.owner = owner;
      address approved = oldZones.getApproved(zone.id);
      if (approved == address(mapZones)) { // Zone can be migrated
        zone.status = ZoneStatus.MIGRATE_READY;
      } else { // Zone needs approval to be migrated
        zone.status = ZoneStatus.MIGRATE_NEEDED;
      }
    } else { // NFT not minted yet
      if (zone.pendingOwner == address(0)) { // User transferred the zone without preparing it
        zone.status = ZoneStatus.RECOVERY_NEEDED_OLD;
      } else { // Zone was prepared and transferred
        zone.status = ZoneStatus.WRAP_READY_OLD;
      }
    }
  }

  function getZone(uint256 zoneId) public view returns (Zone memory zone) {
    (zone.id, zone.owner, zone.sellPrice) = map.getZone(zoneId);
    if (zone.owner == address(mapZones)) {
      writeStatus(zone);
    } else if (zone.owner == address(oldZones)) {
      writeStatusOld(zone);
    } else {
      zone.pendingOwner = mapZones.pendingZoneOwners(zone.id);
      if (zone.pendingOwner != address(0)) {
        zone.status = ZoneStatus.WRAP_PENDING;
      }
    }
  }

  function getAllZones() external view returns (Zone[] memory zones) {
    zones = new Zone[](178);
    for (uint256 i; i < 178; i++) {
      zones[i] = getZone(i + 1);
    }
  }

  function getZonesForSale() external view returns (Zone[] memory zones) {
    zones = new Zone[](178);
    uint256 n;
    for (uint256 i; i < 178; i++) {
      Zone memory zone = getZone(i + 1);
      if (zone.sellPrice > 0) {
        zones[n++] = zone;
      }
    }
    assembly { mstore(zones, n) }
  }
}