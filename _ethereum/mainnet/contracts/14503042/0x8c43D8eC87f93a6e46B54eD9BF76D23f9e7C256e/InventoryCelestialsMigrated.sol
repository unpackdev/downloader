// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./Structs.sol";
import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";

// solhint-disable quotes

contract InventoryCelestialsMigrated is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint8;

  /*  +---+-----------+ */
  /*  | 0 | Body      | */
  /*  +---+-----------+ */


    /*///////////////////////////////////////////////////////////////
                    INITIALIZER 
    //////////////////////////////////////////////////////////////*/


  function initialize() public initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
  }

  function _authorizeUpgrade(address) internal onlyOwner override {}

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

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

  function getAttributes(CelestialV2 memory character, uint256 id) external pure returns (bytes memory) {
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
        '"},',
        '{"trait_type": "Forging", "value": "',
        character.forging.toString(),
        '"}'
      );
  }

  function getImage(uint256 id, CelestialV2 memory character) external view returns (bytes memory) {
    if (character.forging == 11) {
      if (id <= 10_000) {
        return 
          abi.encodePacked(
            _buildImage(_layers[3].data),
            _buildImage(_layers[0].data)
          );
      }
      if (id <= 20_000) {
        return 
          abi.encodePacked(
            _buildImage(_layers[3].data),
            _buildImage(_layers[1].data)
          );
      } else {
        return 
          abi.encodePacked(
            _buildImage(_layers[3].data),
            _buildImage(_layers[2].data)
          );
      }
    } else {
      if (id <= 10_000) return _buildImage(_layers[0].data);
      if (id <= 20_000) return _buildImage(_layers[1].data);
      return _buildImage(_layers[2].data);
    }
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
