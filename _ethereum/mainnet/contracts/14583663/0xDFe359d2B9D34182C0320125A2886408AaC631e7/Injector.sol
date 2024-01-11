// SPDX-License-Identifier: MIT

/// @title  ETHTerrestrials by Kye - Mask injector contract
/// @notice Permit holders to add an image mask to their EthT
/// @dev Proxies the V2 descriptor in order to allow holders to optionally add a trait

pragma solidity ^0.8.7;
import "./IEthTerrestrials.sol";
import "./IEthTerrestrialsV2Descriptor.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./SSTORE2.sol";
import "./Ownable.sol";

contract EthTerrestrialsInjector is Ownable {
   using Strings for uint256;

   IEthTerrestrialsV2Descriptor public v2descriptor = IEthTerrestrialsV2Descriptor(0xEdAC00935844245e40218F418cC6527C41513B25);
   IEthTerrestrials public ethTerrestrials = IEthTerrestrials(0xd65c5D035A35F41f31570887E3ddF8c3289EB920);

   struct Mask {
      address imageStore; //SSTORE2 storage location for SVG image data
      bool isSpecial;
      address imageStore2;
      uint8 removeTraitTypeIfSpecial;
   }

   mapping(uint256 => Mask) masks; 
   mapping(uint256 => uint256) tokenIdMaskSelected; // tokenId => maskNumber
   mapping(uint256 => mapping (uint256 => bool)) specialMaskAllowList; // masknumber ==> tokenId ==> bool

   /// @notice Allow owners of v2 EthTerrestrials (non one-of-one) to add an image "mask" at any time
   /// @notice Fully reversible by setting the mask to 0.
   /// @notice Certain masks are restricted to NFTs having certain attributes
   /// @param tokenId, the tokenId to add an image mask to
   /// @param maskChoice, the mask # to select (0 to remove)
   function setMaskPerToken(uint256 tokenId, uint256 maskChoice) external {
      require(msg.sender == ethTerrestrials.ownerOf(tokenId), "You do not hold this EthT");
      require(tokenId >= 112 && tokenId <= 4269, "Not available for genesis or 1/1 EthTs");
      require(
         maskChoice == 0 || masks[maskChoice].imageStore != address(0),
         "Unavailable option"
      ); //Prevents users from choosing a mask that does not exist

      if (masks[maskChoice].isSpecial) require(specialMaskAllowList[maskChoice][tokenId],"You do not meet the criteria to use this trait");

      tokenIdMaskSelected[tokenId] = maskChoice;
   }

   /// @notice Pass through proxy methods
   function getSvgCustomToken(uint256 tokenId) public view returns (string memory) {
      return v2descriptor.getSvgCustomToken(tokenId);
   }

   function getSvgFromSeed(uint8[10] memory seed) public view returns (string memory) {
      return v2descriptor.getSvgFromSeed(seed);
   }

   function processRawSeed(uint256 rawseed) external view returns (uint8[10] memory) {
      return v2descriptor.processRawSeed(rawseed);
   }

   /// @notice Intercepts calls from the main NFT contract and, if a mask is selected, adds it and generates a tokenURI. Otherwise serves as a direct proxy.
   function generateTokenURI(
      uint256 tokenId,
      uint256 rawSeed,
      uint256 tokenType
   ) public view returns (string memory) {
      uint256 maskNumber = tokenIdMaskSelected[tokenId];
      //If no mask is selected, pass through the request to the v2 descriptor
      if (maskNumber == 0) return v2descriptor.generateTokenURI(tokenId, rawSeed, tokenType);
      //Otherwise, add the mask
      else return inject(tokenId, rawSeed, tokenType, maskNumber);
   }

   /// @notice Reproduces the tokenURI from the v2 descriptor but modifies the image as needed to add the mask
   function inject(
      uint256 tokenId,
      uint256 rawSeed,
      uint256 tokenType,
      uint256 maskNumber
   ) public view returns (string memory) {
      string memory name = string(abi.encodePacked("EtherTerrestrial #", tokenId.toString()));
      string
         memory description = "EtherTerrestrials are inter-dimensional Extra-Terrestrials who came to Earth's internet to infuse consciousness into all other pixelated Lifeforms. They can be encountered in the form of on-chain characters as interpreted by the existential explorer Kye."; //need to write
      string memory traits_json;

      uint8[10] memory seed = v2descriptor.processRawSeed(rawSeed);
      traits_json = v2descriptor.viewTraitsJSON(seed);
      //clear background and circle from *image* but not *attributes* by setting to empty mapping slots.
      seed[0] = 100;
      seed[9] = 100;
      //we may also need to move certain traits out of the way to add the mask
      if (masks[maskNumber].isSpecial) seed[masks[maskNumber].removeTraitTypeIfSpecial] = 100;

      (string memory header, string memory body) = getMaskSvg(maskNumber);
      string memory image = string(abi.encodePacked(header, v2descriptor.getSvgFromSeed(seed), body));

      string memory json = Base64.encode(
         bytes(
            string(
               abi.encodePacked(
                  '{"name": "',
                  name,
                  '", "description": "',
                  description,
                  '", "attributes":',
                  traits_json,
                  ',"image": "',
                  "data:image/svg+xml;base64,",
                  Base64.encode(bytes(image)),
                  '"}'
               )
            )
         )
      );

      string memory output = string(abi.encodePacked("data:application/json;base64,", json));
      return output;
   }

   function getMaskSvg(uint256 maskNumber) public view returns (string memory, string memory) {
      string memory header = string(SSTORE2.read(masks[maskNumber].imageStore));
      string memory body = string(SSTORE2.read(masks[maskNumber].imageStore2));
      return (header, body);
   }

   /// @notice Uploads masks
   /// @param _maskNumber, the number of the mask (stored via mapping so it can be deleted or overwritten), must be greater than zero. Zero is "no mask".
   /// @param _svgHeader, the SVG header tag and any other data that should be inserted before the EthT 
   /// @param _svgBody, any SVG data that should be inserted after the EthT and an SVG close tag - both SVG header and SVG body are required!
   /// @param _isSpecial, whether the trait is special (limited to certain token attributes)
   /// @param _removeTraitTypeIfSpecial, if the trait is special, allows removal of certain attributes from the image that may interfere
   function uploadMask(
      uint256 _maskNumber,
      string memory _svgHeader,
      string memory _svgBody,
      bool _isSpecial,
      uint8 _removeTraitTypeIfSpecial
   ) external onlyOwner {
      require(_maskNumber != 0,"cannot use the zero trait");
      require(bytes(_svgHeader).length!=0 && bytes(_svgBody).length!=0, "Both header and body must be utilized");
      masks[_maskNumber] = Mask({imageStore: SSTORE2.write(bytes(_svgHeader)), imageStore2: SSTORE2.write(bytes(_svgBody)), isSpecial:_isSpecial, removeTraitTypeIfSpecial:_removeTraitTypeIfSpecial});
   }

   /// @notice Sets an allowlist for special traits
   /// @param _maskNumber, the number of the mask to be designated as special
   /// @param _allowListTokenIds, a list of tokenIds that may choose the trait
   /// @param _setting, a toggle to add/remove from the allowlist
   /// @dev Allowlist used instead of onchain seed verification becuase calls to read the token seed in a write operation are gas inefficient
   function setSpecialMaskAllowlist(
      uint256 _maskNumber,
      uint256[] memory _allowListTokenIds,
      bool _setting
   ) external onlyOwner {
      require(_maskNumber != 0, "cannot use the zero trait");
      require(masks[_maskNumber].isSpecial, "mask not flagged as special");
      for (uint256 i; i<_allowListTokenIds.length; i++) {
         specialMaskAllowList[_maskNumber][_allowListTokenIds[i]]=_setting;
      }
   }

}
