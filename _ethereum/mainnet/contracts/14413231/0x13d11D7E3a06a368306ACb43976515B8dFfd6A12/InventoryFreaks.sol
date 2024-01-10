// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Structs.sol";
import "./Strings.sol";
import "./Ownable.sol";

// solhint-disable quotes

contract InventoryFreaks is Ownable {
  using Strings for uint8;

  /*  +---+-----------+ */
  /*  | 0 | Body      | */
  /*  +---+-----------+ */
  /*  | 1 | Armor     | */
  /*  +---+-----------+ */
  /*  | 2 | Main Hand | */
  /*  +---+-----------+ */
  /*  | 3 | Off Hand  | */
  /*  +---+-----------+ */

  /*///////////////////////////////////////////////////////////////
                LAYERS LOGIC 
    //////////////////////////////////////////////////////////////*/

  mapping(uint256 => mapping(uint256 => Layer)[4]) internal _layers;

  function addLayers(LayerInput[] memory inputs, uint256 species) external onlyOwner {
    for (uint256 i = 0; i < inputs.length; i++) {
      _layers[species][inputs[i].layerIndex][inputs[i].itemIndex] = Layer(inputs[i].name, inputs[i].data);
    }
  }

  function getLayer(uint8 layerIndex, uint8 itemIndex, uint256 species) external view returns (Layer memory) {
    return _layers[species][layerIndex][itemIndex];
  }

  /*///////////////////////////////////////////////////////////////
                URI LOGIC 
    //////////////////////////////////////////////////////////////*/

  function getAttributes(Freak memory character, uint256 id) external view returns (bytes memory) {
    return
      abi.encodePacked(
        '{"trait_type": "Type", "value": "Freak"},',
        '{"trait_type": "Generation", "value":"',
        id == 0 ? "Gen 0" : id == 1 ? "Gen 1" : "Gen 2",
        '"},'
        '{"trait_type": "Species", "value": "',
        character.species == 1 ? "Troll" : character.species == 2 ? "Fairy" : "Ogre",
        '"},'
        '{"trait_type": "Body", "value": "',
        _layers[character.species][0][character.body].name,
        '"},',
        '{"trait_type": "Armor", "value": "',
        _layers[character.species][1][character.armor].name,
        '"},',
        '{"trait_type": "Main Hand", "value": "',
        _layers[character.species][2][character.mainHand].name,
        '"},',
        '{"trait_type": "Off Hand", "value": "',
        _layers[character.species][3][character.offHand].name,
        '"},',
        '{"trait_type": "Power", "value": "',
        character.power.toString(),
        '"},',
        '{"trait_type": "Health", "value": "',
        character.health.toString(),
        '"},',
        '{"trait_type": "Critical Strike Mod", "value": "',
        character.criticalStrikeMod.toString(),
        '"}'
      );
  }

  function getImage(Freak memory character) external view returns (bytes memory) {
    if(character.offHand == 0){
      return
        abi.encodePacked(
          _buildImage(_layers[character.species][0][character.body].data),
          _buildImage(_layers[character.species][1][character.armor].data),
          _buildImage(_layers[character.species][2][character.mainHand].data)
        );
    }else{
      return
        abi.encodePacked(
          _buildImage(_layers[character.species][0][character.body].data),
          _buildImage(_layers[character.species][1][character.armor].data),
          _buildImage(_layers[character.species][2][character.mainHand].data),
          _buildImage(_layers[character.species][3][character.offHand].data)
        );
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
