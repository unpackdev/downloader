// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Base64.sol";
import "./InterfacesMigrated.sol";
import "./Strings.sol";
import "./Ownable.sol";

// solhint-disable quotes

contract MetadataHandlerMigrated is Ownable {
  using Strings for uint256;

  InventoryCelestialsLike public inventoryCelestials;

  InventoryFreaksLike public inventoryFreaks;

  constructor(address newInventoryCelestials, address newInventoryFreaks) {
    inventoryCelestials = InventoryCelestialsLike(newInventoryCelestials);
    inventoryFreaks = InventoryFreaksLike(newInventoryFreaks);
  }

  function setInventories(address newInventoryCelestials, address newInventoryFreaks) external onlyOwner {
    inventoryCelestials = InventoryCelestialsLike(newInventoryCelestials);
    inventoryFreaks = InventoryFreaksLike(newInventoryFreaks);
  }

  function getCelestialTokenURI(uint256 id, CelestialV2 memory character) external view returns (string memory) {
    bytes memory name = abi.encodePacked("Celestial #", id.toString());
    bytes memory attributes = inventoryCelestials.getAttributes(character, id);
    bytes memory svg = _buildSVG(inventoryCelestials.getImage(id, character));
    return string(_buildJSON(name, attributes, svg));
  }

  function getFreakTokenURI(uint256 id, Freak memory character) external view returns (string memory) {
    bytes memory name = abi.encodePacked("Freak #", id.toString());
    bytes memory attributes = inventoryFreaks.getAttributes(character, id);
    bytes memory svg = _buildSVG(inventoryFreaks.getImage(character));
    return string(_buildJSON(name, attributes, svg));
  }

  function _buildSVG(bytes memory data) internal pure returns (bytes memory) {
    bytes memory output = abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="character" width="100%" height="100%" version="1.1" viewBox="0 0 64 64">',
      data,
      "<style>#character{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
    );

    return abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(output)));
  }

  function _buildJSON(
    bytes memory name,
    bytes memory attributes,
    bytes memory image
  ) internal pure returns (bytes memory) {
    bytes memory output = abi.encodePacked(
      '{"name":"',
      name,
      '","description":"Build your guild, battle your foes with the first on-chain PvP. Hunt for fortune and glory shall be yours!","attributes":[',
      attributes,
      '],"image":"',
      image,
      '"}'
    );

    return abi.encodePacked("data:application/json;base64,", Base64.encode(output));
  }
}
