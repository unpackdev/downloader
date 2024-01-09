// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./IHND.sol";

contract Traits is Ownable, ITraits {

  using Strings for uint256;

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    string png;
  }

  // mapping from trait type (index) to its name
  string[10] private _traitTypes = [
    "Body",
    "Eyes",
    "Face",
    "Headpiece",
    "Tail",
    "Armor",
    "Gloves",
    "Weapon",
    "Shoes",
    "Shield"
  ];
  // storage of each traits name and base64 PNG data
  mapping(uint8 => mapping(uint8 => Trait)) public traitData;
  // mapping from rankIndex to its score
  string[4] private _ranks = [
    "8",
    "7",
    "6",
    "5"
  ];

  IHND public hndNFT;

  constructor() {}

  /** ADMIN */

  function setHND(address _hndNFT) external onlyOwner {
    hndNFT = IHND(_hndNFT);
  }

  function uploadTraits(uint8 traitType, uint8[] calldata traitIds, string[] calldata traitNames, string[] calldata traitPngs) external onlyOwner {
    require(traitIds.length == traitNames.length, "Mismatched inputs");
    for (uint i = 0; i < traitIds.length; i++) {
      traitData[traitType][traitIds[i]] = Trait(
        traitNames[i],
        traitPngs[i]
      );
    }
  }

  /** RENDER */

  /**
   * generates an <image> element using base64 encoded PNGs
   * @param trait the trait storing the PNG data
   * @return the <image> element
   */
  function drawTrait(Trait memory trait) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
      trait.png,
      '"/>'
    ));
  }

  /**
   * generates an entire SVG by composing multiple <image> elements of PNGs
   * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the Hero / Demon
   */
  function drawSVG(uint256 tokenId) internal view returns (string memory) {
    IHND.HeroDemon memory s = hndNFT.getTokenTraits(tokenId);


    // t.isFemale is cast as 0/1 for false/true
    uint8 isFemale;
    if (s.isFemale) {
        isFemale = 1;
    } 

    string memory svgString;

    if (s.isHero) {   
      svgString = string(abi.encodePacked(
       drawTrait(traitData[0][s.body]),
       drawTrait(traitData[1 + isFemale][s.face]),
       drawTrait(traitData[3 + isFemale][s.headpiecehorns]),
       drawTrait(traitData[5 + isFemale][s.armor]),
       drawTrait(traitData[7][s.gloves]),
       drawTrait(traitData[8][s.shoes]),
       drawTrait(traitData[10][s.shield]),
       drawTrait(traitData[9][s.weapon])
       
      ));
            
    } else {
       svgString = string(abi.encodePacked(
        drawTrait(traitData[11][s.body]),
        drawTrait(traitData[12][s.eyes]),
        drawTrait(traitData[13][s.headpiecehorns]),
        drawTrait(traitData[14][s.tailflame]),
        drawTrait(traitData[15][s.armor]),
        drawTrait(traitData[16][s.weapon])
      ));
            
    }

    return string(abi.encodePacked(
      '<svg id="hndNFT" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  /**
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) internal view returns (string memory) {
    IHND.HeroDemon memory s = hndNFT.getTokenTraits(tokenId);
    string memory traits;

    uint8 isFemale;
    if (s.isFemale) {
        isFemale = 1;
    } 

    if (s.isHero) {
                
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[0][s.body].name),',',
        attributeForTypeAndValue(_traitTypes[1 + isFemale], traitData[1 + isFemale][s.face].name),',',
        attributeForTypeAndValue(_traitTypes[3 + isFemale], traitData[3 + isFemale][s.headpiecehorns].name),',',
        attributeForTypeAndValue(_traitTypes[5 + isFemale], traitData[5 + isFemale][s.armor].name),',',
        attributeForTypeAndValue(_traitTypes[6], traitData[7][s.gloves].name),',',
        attributeForTypeAndValue(_traitTypes[8], traitData[8][s.shoes].name),',',
        attributeForTypeAndValue(_traitTypes[9], traitData[10][s.shield].name),',',
        attributeForTypeAndValue(_traitTypes[7], traitData[9][s.weapon].name),','
      ));

    } else {

      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[11][s.body].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[12][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[13][s.headpiecehorns].name),',',
        attributeForTypeAndValue(_traitTypes[4], traitData[14][s.tailflame].name),',',
        attributeForTypeAndValue(_traitTypes[8], traitData[15][s.armor].name),',',
        attributeForTypeAndValue(_traitTypes[7], traitData[16][s.weapon].name),',',
        attributeForTypeAndValue("Rank Score", _ranks[s.rankIndex]),','
      ));
    }
    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Generation","value":',
      tokenId <= hndNFT.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
      '},{"trait_type":"Type","value":',
      s.isHero ? '"Hero"' : '"Demon"',
      '}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_msgSender() == address(hndNFT), "hmmmm what doing?");
    IHND.HeroDemon memory s = hndNFT.getTokenTraits(tokenId);

    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      s.isHero ? 'Hero #' : 'Demon #',
      tokenId.toString(),
      '", "description": "A Great War Has Broken Out In The Kingdom Of Fantasia. Play As Heroes And Demons In The War. Earn Experience In The Form Of $EXP Tokens In Battle. Spend $EXP In-Game. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
      base64(bytes(drawSVG(tokenId))),
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
}