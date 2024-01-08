// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;
pragma abicoder v2;
import "./console.sol";

import "./IEthMap.sol";

interface IZones {
  function ownerOf(uint256) external view returns (address);

  function pendingZoneOwners(uint256) external view returns (address);
}

contract Lens {
  IEthMap public constant map = IEthMap(0xB6bbf89c3DbBa20Cb4d5cABAa4A386ACbbAb455e);
  IZones public immutable mapZones;

  enum ZoneStatus {
    BASE,
    WRAP_PENDING,
    WRAP_READY,
    WRAPPED
  }

  struct Zone {
    ZoneStatus status;
    address pendingOwner;
    uint id;
    address owner;
    uint sellPrice;
  }

  constructor(address zones) {
    mapZones = IZones(zones);
  }

  function getZone(uint256 zoneId) public view returns (Zone memory zone) {
    console.log("--getZone--");
    (zone.id, zone.owner, zone.sellPrice) = map.getZone(zoneId);
    zone.pendingOwner = mapZones.pendingZoneOwners(zoneId);
    if (zone.owner == address(mapZones)) {
      console.log("zone owned by wrapper");
      try mapZones.ownerOf(zoneId) returns (address owner) {
        console.log("got owner");
        zone.owner = owner;
        zone.status = ZoneStatus.WRAPPED;
      } catch {
        console.log("owner call reverted");
        if (zone.pendingOwner != address(0)) {
          console.log("pendingOwner set");
          zone.status = ZoneStatus.WRAP_READY;
        } else {
          console.log("pendingOwner not set");
        }
      }
    } else {
      console.log("zone not owned by wrapper");
      if (zone.pendingOwner != address(0)) {
        console.log("pendingOwner set");
        zone.status = ZoneStatus.WRAP_PENDING;
      } else {
          console.log("pendingOwner not set");
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