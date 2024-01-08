// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./IERC165.sol";
import "./ERC165.sol";
import "./Zones.sol";
import "./FurProxy.sol";

/// @title IZone
/// @author LFG Gaming LLC
/// @notice The loot engine is patchable by replacing the Furballs' engine with a new version
interface IZone is IERC165 {
  function number() external view returns(uint);

  function name() external view returns(string memory);

  function background() external view returns(string memory);

  function enterZone(uint256 tokenId) external;
}


contract ZoneDefinition is ERC165, IZone, FurProxy {
  uint override public number;

  string override public name;

  string override public background;

  constructor(address furballsAddress, uint32 zoneNum) FurProxy(furballsAddress) {
    number = zoneNum;
  }

  function update(string calldata zoneName, string calldata zoneBk) external gameAdmin {
    name = zoneName;
    background = zoneBk;
  }

  /// @notice A zone can hook a furball's entry...
  function enterZone(uint256 tokenId) external override gameAdmin {
    // Nothing to see here.
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IZone).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}
