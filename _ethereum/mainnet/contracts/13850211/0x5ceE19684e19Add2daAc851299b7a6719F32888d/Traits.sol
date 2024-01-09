// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./IDefpunk.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
  }

  // mapping from trait type (index) to its name
  string[9] _traitTypes = [
    "Background", // 0
    "Skin", // 1
    "Nose", // 2
    "Eyes", // 3
    "Neck", // 4
    "Mouth", // 5
    "Ears", // 6
    "Hair", // 7
    "Mouth Accessory" // 8
  ];
  // storage of each traits name and base64 PNG data
  mapping(uint8 => mapping(uint8 => Trait)) public traitData;
  
  IDefpunk public defpunkNFT;

  constructor() {}

  /** ADMIN */

  function setDefpunk(address _defpunk) external onlyOwner {
    defpunkNFT = IDefpunk(_defpunk);
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and base64 encoded PNGs for each trait
   */
  function uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    for (uint i = 0; i < traits.length; i++) {
      traitData[traitType][traitIds[i]] = Trait(
        traits[i].name
      );
    }
  }

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory traitType, string memory value, bool aged) internal pure returns (string memory) {
    if (aged) {
      return string(abi.encodePacked(
        '{"trait_type":"',
        traitType,
        '","value":"',
        value, ' (Aged)',
        '"}'
      ));
    } else {
      return string(abi.encodePacked(
        '{"trait_type":"',
        traitType,
        '","value":"',
        value,
        '"}'
      ));
    }

  }

  /**
  * @dev gets the base URI
  */
  function getBaseURI() external view returns (string memory) {
    return defpunkNFT.getBaseURI();
  }

  /**
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    IDefpunk.Defpunk memory d = defpunkNFT.getTokenTraits(tokenId);
    string memory traits;
    if (d.isMale) {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[1][d.background].name, false),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[2][d.skin].name, d.aged[0] == 2),',',
        attributeForTypeAndValue(_traitTypes[2], traitData[3][d.nose].name, false),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[4][d.eyes].name, false),',',
        attributeForTypeAndValue(_traitTypes[4], traitData[5][d.neck].name, false),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[6][d.mouth].name, d.aged[1] == 6), ',',
        attributeForTypeAndValue(_traitTypes[6], traitData[7][d.ears].name, false),',',
        attributeForTypeAndValue(_traitTypes[7], traitData[8][d.hair].name, d.aged[2] == 8), ',',
        attributeForTypeAndValue(_traitTypes[8], traitData[9][d.mouthAccessory].name, false),',',
        attributeForTypeAndValue("Fusion Index", uint2str(d.fusionIndex), false),','
      ));
    } else {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[10][d.background].name, false),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[11][d.skin].name, d.aged[0] == 11),',',
        attributeForTypeAndValue(_traitTypes[2], traitData[12][d.nose].name, false),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[13][d.eyes].name, false),',',
        attributeForTypeAndValue(_traitTypes[4], traitData[14][d.neck].name, false),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[15][d.mouth].name, false),',',
        attributeForTypeAndValue(_traitTypes[6], traitData[16][d.ears].name, false),',',
        attributeForTypeAndValue(_traitTypes[7], traitData[17][d.hair].name, d.aged[2] == 17),',',
        attributeForTypeAndValue(_traitTypes[8], traitData[18][d.mouthAccessory].name, false),',',
        attributeForTypeAndValue("Fusion Index", uint2str(d.fusionIndex), false),','
      ));
    }

    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Gender","value":',
      d.isMale ? '"Male"' : '"Female"',
      '}]'
    ));
  }

  function traitHasAged(uint8[3] memory aged, uint8 traitIndex) internal pure returns (bool) {
    for (uint i = 0; i < aged.length; i++) {
      if (aged[i] == traitIndex) return true;
    }
    return false;
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      'Defpunk #',
      tokenId.toString(),
      '", "description": "This is the Defpunk description. All the metadata and are generated and stored 100% on-chain.", "image": "',
      defpunkNFT.getBaseURI(),
      tokenId.toString(),
      '", "attributes":',
      compileAttributes(tokenId),
      "}"
    ));

    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  /** BASE 64 - Written by Brech Devos */
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
