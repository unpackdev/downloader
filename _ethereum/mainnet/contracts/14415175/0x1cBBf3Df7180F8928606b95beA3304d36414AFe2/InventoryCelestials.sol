// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Structs.sol";
import "./Strings.sol";
import "./Ownable.sol";

// solhint-disable quotes

contract InventoryCelestials is Ownable {
  using Strings for uint8;

  /*  +---+-----------+ */
  /*  | 0 | Body      | */
  /*  +---+-----------+ */

  /*///////////////////////////////////////////////////////////////
                LAYERS LOGIC 
    //////////////////////////////////////////////////////////////*/

  mapping(uint256 => Layer) internal _layers;

  function addLayers(LayerInput[] memory inputs) external onlyOwner {
    for (uint256 i = 0; i < inputs.length; i++) {
      _layers[inputs[i].layerIndex] = Layer(inputs[i].name, inputs[i].data);
    }
  }

  function getLayer(uint8 layerIndex) external view returns (Layer memory) {
    return _layers[layerIndex];
  }

  /*///////////////////////////////////////////////////////////////
                URI LOGIC 
    //////////////////////////////////////////////////////////////*/

  function getAttributes(Celestial memory character, uint256 id) external pure returns (bytes memory) {
    return
      abi.encodePacked(
        '{"trait_type": "Type", "value": "Celestial"},',
        '{"trait_type": "Generation", "value":"',
        id <= 10000 ? "Gen 0" : id <= 20000 ? "Gen 1" : "Gen 2",
        '"},'
        '{"trait_type": "Health Modifier", "value": "',
        character.healthMod.toString(),
        '"},'
        '{"trait_type": "Power Modifier", "value": "',
        character.powMod.toString(),
        '"},',
        '{"trait_type": "Pilfer Power", "value": "',
        character.cPP.toString(),
        '"},',
        '{"trait_type": "Level", "value": "',
        character.cLevel.toString(),
        '"}'
      );
  }

  function getImage(uint256 id) external view returns (bytes memory) {
    if (id <= 10_000) return _buildImage(_layers[0].data);
    if (id <= 20_000) return _buildImage(_layers[1].data);
    return _buildImage(_layers[2].data);
  }

  function _buildImage(string memory image) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
        image,
        '"/>'
      );
  }
}
