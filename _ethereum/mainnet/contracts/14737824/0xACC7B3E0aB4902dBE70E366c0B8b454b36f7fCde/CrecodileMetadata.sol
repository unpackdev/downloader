//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";

/*

__          ________ _      _____ ____  __  __ ______   _        
\ \        / /  ____| |    / ____/ __ \|  \/  |  ____| | |       
 \ \  /\  / /| |__  | |   | |   | |  | | \  / | |__    | |_ ___  
  \ \/  \/ / |  __| | |   | |   | |  | | |\/| |  __|   | __/ _ \ 
   \  /\  /  | |____| |___| |___| |__| | |  | | |____  | || (_) |
    \/  \/   |______|______\_____\____/|_|  |_|______|  \__\___/ 

  _____ _____  ______ _____ ____  _               _   _ _____  
 / ____|  __ \|  ____/ ____/ __ \| |        /\   | \ | |  __ \ 
| |    | |__) | |__ | |   | |  | | |       /  \  |  \| | |  | |
| |    |  _  /|  __|| |   | |  | | |      / /\ \ | . ` | |  | |
| |____| | \ \| |___| |___| |__| | |____ / ____ \| |\  | |__| |
 \_____|_|  \_\______\_____\____/|______/_/    \_\_| \_|_____/ 

🐊🐊🐊
*/

interface IRenderer {
  function imageData(uint256 dna) external view returns (string memory);
}

interface IDna {
  function getDNA(uint256 tokenId) external view returns(uint256);
}

contract CrecodileMetadata is Ownable {

    using Strings for uint256;

    // definitions
    struct TraitType {
      // display_type
      string trait_type;
      uint8 index;
    }

    // instances
    struct Trait {
      string trait_type;
      uint256 trait_index;
      string value;
    }

    // https://docs.opensea.io/docs/metadata-standards
    struct Metadata {
      string name;
      string description;
      string external_url;
      //string image computed: basePath + dna + extension
      string image_base_uri;
      string image_extension;

      address image_data;
      string animation_url;
      // attributes
    }

    TraitType[] public traits;

    // trait_type => index => value
    mapping(uint256 => mapping(uint256 => string)) public traitValues;

    Metadata public metadata;

    address public dnaContract;

    // 8 bits per trait
    // 255 = 1111 1111
    uint256 constant TRAIT_MASK = 255;

    // constructor() {}

    // O W N E R

    function writeTraitTypes(string[] memory trait_types) public onlyOwner  {
      for (uint8 index = 0; index < trait_types.length; index++) {
        traits.push(TraitType(trait_types[index], index));
      }
    }

    function setTraitType(uint8 trait_type_idx, string memory trait_type) public onlyOwner {
      traits[trait_type_idx] = TraitType(trait_type, trait_type_idx);
    }

    function setTrait(uint8 trait_type, uint8 trait_idx, string memory value) public onlyOwner {
      traitValues[trait_type][trait_idx] = value;
    }

    function writeTraitData(uint8 trait_type, uint8 start, uint256 length, string[] memory trait_values) public onlyOwner {
      for (uint8 index = 0; index < length; index++) {
        setTrait(trait_type, start+index, trait_values[index]);
      }
    }

    function setDnaContract(address _dnaContract) public onlyOwner {
      dnaContract = _dnaContract;
    }

    function setMetadata(Metadata memory _metadata) public onlyOwner {
      metadata = _metadata;
    }

    function setDescription(string memory description) public onlyOwner {
      metadata.description = description;
    }

    function setExternalUrl(string memory external_url) public onlyOwner {
      metadata.external_url = external_url;
    }

    function setImage(string memory image_base_uri, string memory image_extension) public onlyOwner {
      metadata.image_base_uri = image_base_uri;
      metadata.image_extension = image_extension;
    }

    function setImageData(address imageData) public onlyOwner {
      metadata.image_data = imageData;
    }

    function setAnimationUrl(string memory animation_url) public onlyOwner {
      metadata.animation_url = animation_url;
    }

    // P U B L I C

    function dnaToTraits(uint256 dna) public view returns (Trait[] memory) {
      uint256 trait_count = traits.length;
      Trait[] memory tValues = new Trait[](trait_count);
      for (uint256 i = 0; i < trait_count; i++) {
        uint256 bitMask = TRAIT_MASK << (8 * i);
        uint256 trait_index = (dna & bitMask) >> (8 * i);
        string memory value = traitValues[ traits[i].index ][trait_index];
        tValues[i] = Trait(traits[i].trait_type, trait_index, value);
      }
      return tValues;
    }

    function getAttributesJson(uint256 dna) internal view returns (string memory) {
      Trait[] memory _traits = dnaToTraits(dna);
      uint8 trait_count = uint8(traits.length);
      string memory attributes = '[\n';
      for (uint8 i = 0; i < trait_count; i++) {
        attributes = string(abi.encodePacked(attributes,
          '{"trait_type": "', _traits[i].trait_type, '", "value": "', _traits[i].value,'"}', i < (trait_count - 1) ? ',' : '','\n'
        ));
      }
      return string(abi.encodePacked(attributes, ']'));
    }

    function getImage(uint256 dna) internal view returns (string memory) {
      return bytes(metadata.image_base_uri).length > 0 ? string(abi.encodePacked(metadata.image_base_uri, dna.toString(), metadata.image_extension)) : "";
    }

    function getImageData(uint256 dna) internal view returns (string memory) {
      if (metadata.image_data != address(0x0)) {
        return IRenderer(metadata.image_data).imageData(dna);
      }
      return "";
    }

    function getMetadataJson(uint256 tokenId, uint256 dna) public view returns (string memory){
      string memory attributes = getAttributesJson(dna);
      string memory image_data = getImageData(dna);
      string memory meta = string(
        abi.encodePacked(
          '{\n"name": "', metadata.name,' #', tokenId.toString(),
          '"\n,"description": "', metadata.description,
          '"\n,"attributes":', attributes,
          '\n,"external_url": "', metadata.external_url, tokenId.toString()
        )
      );
      if (bytes(metadata.animation_url).length > 0) {
        meta = string(
          abi.encodePacked(
            meta,
            '"\n,"animation_url": "', metadata.animation_url, tokenId.toString()
          )
        );
      }
      if (bytes(metadata.image_base_uri).length > 0) {
        meta = string(
          abi.encodePacked(
            meta,
            '"\n,"image": "', getImage(dna)
          )
        );
      } 
      else if(bytes(image_data).length > 0) {
        meta = string(
          abi.encodePacked(
            meta,
            '"\n,"image_data": "', image_data
          )
        );
      }

      return string(
        abi.encodePacked(
          meta,
          '"\n}'
        )
      );
    }

    function tokenURI(uint256 tokenId, uint256 dna) public view returns (string memory) {
      string memory json = Base64.encode(bytes(getMetadataJson(tokenId, dna)));
      string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
      );
      return output;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
      if(address(dnaContract) == address(0x0)) {
        return "";
      }
      uint256 dna = IDna(dnaContract).getDNA(tokenId);
      return tokenURI(tokenId, dna);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
