//	SPDX-License-Identifier: MIT

/// @title  ETHTerrestrials by Kye descriptor (v1). An on-chain migration of assets from the OpenSea shared storefront token.
/// @notice Image and traits stored on-chain (non-generative)

pragma solidity ^0.8.0;

import "./InflateLib.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./SSTORE2.sol";

contract EthTerrestrialsGenesisDescriptor {
   using Strings for uint8;
   using Strings for uint256;
   using InflateLib for bytes;

   /// @notice Storage entry for a token
   struct Token {
      address imageStore; //SSTORE2 storage location for a base64 encoded PNG, compressed using DEFLATE (python zlib). Header (first 2 bytes) and checksum (last 4 bytes) truncated.
      uint96 imagelen; //The length of the uncomressed image data (required for decompression).
      uint8[] buildCode; //Each token's traits.
   }
   mapping(uint256 => Token) public tokenData;

   /// @notice Storage of the two types of traits
   mapping(uint256 => string) public skincolor;
   mapping(uint256 => string) public accesories;

   /// @notice Storage entry for an animated frame
   struct Frame {
      address imageStore; //SSTORE2 storage location for a base64 encoded PNG, compressed using DEFLATE (python zlib). Header (first 2 bytes) and checksum (last 4 bytes) truncated.
      uint96 imagelen; //The length of the uncomressed image data (required for decompression).
   }

   /// @notice A mapping of frame components for animated tokens in the format animationFrames[tokenId][frame number].
   /// @dev each frame is a base64 encoded PNG. In order to save storage space, each frame PNG only contains pixels that differ from frame 0
   mapping(uint256 => mapping(uint256 => Frame)) public animationFrames;

   /// @notice Permanently seals the metadata in the contract from being modified by deployer.
   bool public contractsealed;

   address private deployer;

   constructor() public {
      deployer = msg.sender;
   }

   modifier onlyDeployerWhileUnsealed() {
      require(!contractsealed && msg.sender == deployer, "Not authorized or locked");
      _;
   }

   string imageTagOpen =
      '<image x="0" y="0" width="24" height="24" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,';

   /*
.___  ___.  _______ .___________.    ___       _______       ___   .___________.    ___      
|   \/   | |   ____||           |   /   \     |       \     /   \  |           |   /   \     
|  \  /  | |  |__   `---|  |----`  /  ^  \    |  .--.  |   /  ^  \ `---|  |----`  /  ^  \    
|  |\/|  | |   __|      |  |      /  /_\  \   |  |  |  |  /  /_\  \    |  |      /  /_\  \   
|  |  |  | |  |____     |  |     /  _____  \  |  '--'  | /  _____  \   |  |     /  _____  \  
|__|  |__| |_______|    |__|    /__/     \__\ |_______/ /__/     \__\  |__|    /__/     \__\ 
*/

   /// @notice Generates a list of traits
   /// @param tokenId, the desired tokenId
   /// @return traits, a string array
   function viewTraits(uint256 tokenId) public view returns (string[] memory) {
      uint256 length = tokenData[tokenId].buildCode.length;
      string[] memory traits = new string[](length);

      for (uint256 i; i < length; i++) {
         uint8 thisTrait = tokenData[tokenId].buildCode[i];
         if (i == 0) {
            traits[i] = skincolor[thisTrait];
         } else {
            traits[i] = accesories[thisTrait];
         }
      }
      return traits;
   }

   /// @notice Generates an ERC721 standard metadata JSON string
   /// @param tokenId, the desired tokenId
   /// @return json, a JSON metadata string
   function viewTraitsJSON(uint256 tokenId) public view returns (string memory) {
      uint256 length = tokenData[tokenId].buildCode.length;
      string[] memory traits = new string[](length);
      traits = viewTraits(tokenId);

      traits[0] = string(abi.encodePacked('[{"trait_type":"Genesis Skin Color","value":"', traits[0], '"}'));

      for (uint256 i = 1; i < length; i++) {
         traits[i] = string(abi.encodePacked(',{"trait_type":"Genesis Accessory","value":"', traits[i], '"}'));
      }

      string memory json = traits[0];
      for (uint256 i = 1; i < length; i++) {
         json = string(abi.encodePacked(json, traits[i]));
      }

      json = string(abi.encodePacked(json, ',{"trait_type":"Life Form","value":"Genesis"}]'));
      return json;
   }

   /// @notice Returns an ERC721 standard tokenURI
   /// @param tokenId, the desired tokenId to display
   /// @return output, a base64 encoded JSON string containing the tokenURI (metadata and image)
   function generateTokenURI(uint256 tokenId) external view returns (string memory) {
      string memory name = string(abi.encodePacked("Genesis EtherTerrestrial #", tokenId.toString()));
      string
         memory description = "EtherTerrestrials are inter-dimensional Extra-Terrestrials who came to Earth's internet to infuse consciousness into all other pixelated Lifeforms. They can be encountered in the form of on-chain characters as interpreted by the existential explorer Kye.";
      string memory traits = viewTraitsJSON(tokenId);
      string memory svg = getSvg(tokenId);

      string memory json = Base64.encode(
         bytes(
            string(
               abi.encodePacked(
                  '{"name": "',
                  name,
                  '", "description": "',
                  description,
                  '", "attributes":',
                  traits,
                  ',"image": "data:image/svg+xml;base64,',
                  Base64.encode(bytes(svg)),
                  '"}'
               )
            )
         )
      );

      string memory output = string(abi.encodePacked("data:application/json;base64,", json));
      return output;
   }

   /// @notice Generates an unencoded SVG image for a given token
   /// @param tokenId, the desired tokenId to display
   /// @dev PNG images are added into an SVG for easy scaling
   /// @return an SVG string
   function getSvg(uint256 tokenId) public view returns (string memory) {
      string
         memory SVG = '<svg id="ETHT" width="100%" height="100%" version="1.1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
      string memory base64encodedPNG = decompress(SSTORE2.read(tokenData[tokenId].imageStore), tokenData[tokenId].imagelen);
      SVG = string(
         abi.encodePacked(
            SVG,
            imageTagOpen,
            base64encodedPNG,
            '"/>',
            tokenId <= 3 ? addAnimations(tokenId) : "",
            "<style>#ETHT{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
         )
      );
      return SVG;
   }

   /// @notice Builds animation layers for certain tokens
   /// @param tokenId, the desired tokenId
   /// @return allAnimatedFrames, a string of SVG components
   function addAnimations(uint256 tokenId) internal view returns (string memory) {
      uint8 numAnimatedFrames;
      string memory duration;
      if (tokenId == 1) {
         numAnimatedFrames = 18;
         duration = "1.33";
      } else if (tokenId == 2) {
         numAnimatedFrames = 32;
         duration = "2.31";
      } else if (tokenId == 3) {
         numAnimatedFrames = 35;
         duration = "2.52";
      }
      string[36] memory frames;
      frames[0] = string(
         abi.encodePacked(
            '<rect><animate  id="b" begin="0;f',
            (numAnimatedFrames - 1).toString(),
            '.end" dur="',
            duration,
            's" attributeName="visibility" from="hide" to="hide"/></rect>'
         )
      );

      for (uint8 i; i < numAnimatedFrames; i++) {
         string memory begin;
         if (i == 0) begin = "b.begin+0.07s";
         else begin = string(abi.encodePacked("f", (i - 1).toString(), ".end"));

         string memory frame = string(
            abi.encodePacked(
               '<g opacity="0">',
               imageTagOpen,
               decompress(SSTORE2.read(animationFrames[tokenId][i].imageStore), animationFrames[tokenId][i].imagelen),
               '"/>',
               '<animate attributeName="opacity" id ="f',
               i.toString(),
               '" begin="',
               begin,
               '" values="1" dur="0.07"  calcMode="discrete"/></g>'
            )
         );
         frames[i + 1] = frame;
      }

      string memory allAnimatedFrames;

      for (uint8 i; i < numAnimatedFrames + 1; i++) {
         allAnimatedFrames = string(abi.encodePacked(allAnimatedFrames, frames[i]));
      }

      return allAnimatedFrames;
   }

   function decompress(bytes memory input, uint256 len) public pure returns (string memory) {
      (, bytes memory decompressed) = InflateLib.puff(input, len);
      return string(decompressed);
   }

   /*
 _______   _______ .______    __        ______   ____    ____  _______ .______      
|       \ |   ____||   _  \  |  |      /  __  \  \   \  /   / |   ____||   _  \     
|  .--.  ||  |__   |  |_)  | |  |     |  |  |  |  \   \/   /  |  |__   |  |_)  |    
|  |  |  ||   __|  |   ___/  |  |     |  |  |  |   \_    _/   |   __|  |      /     
|  '--'  ||  |____ |  |      |  `----.|  `--'  |     |  |     |  |____ |  |\  \----.
|_______/ |_______|| _|      |_______| \______/      |__|     |_______|| _| `._____|
                                                                                                                                                
*/

   /// @notice Establishes the list of accessory traits
   function setSkins(string[] memory _skins, uint256[] memory traitNumber) external onlyDeployerWhileUnsealed {
      require(_skins.length == traitNumber.length);

      for (uint8 i; i < _skins.length; i++) skincolor[traitNumber[i]] = _skins[i];
   }

   /// @notice Establishes the list of accessory traits
   function setAccessories(string[] memory _accesories, uint256[] memory traitNumber) external onlyDeployerWhileUnsealed {
      require(_accesories.length == traitNumber.length);
      for (uint8 i; i < _accesories.length; i++) accesories[traitNumber[i]] = _accesories[i];
   }

   /// @notice Establishes the tokenData for a list of tokens (image and trait build code)
   function setTokenData(
      uint8[] memory _newTokenIds,
      Token[] memory _tokenData,
      bytes[] memory _imageData
   ) external onlyDeployerWhileUnsealed {
      require(_newTokenIds.length == _tokenData.length && _imageData.length == _tokenData.length);
      for (uint8 i; i < _newTokenIds.length; i++) {
         _tokenData[i].imageStore = SSTORE2.write(_imageData[i]);
         tokenData[_newTokenIds[i]] = _tokenData[i];
      }
   }

   /// @notice Establishes the animated frames for a given tokenId
   function setAnimationFrames(
      uint256 _tokenId,
      Frame[] memory _animationFrames,
      uint256[] memory frameNumber,
      bytes[] memory _imageData
   ) external onlyDeployerWhileUnsealed {
      require(_tokenId <= 3);
      require(_animationFrames.length == frameNumber.length && _imageData.length == frameNumber.length);
      for (uint256 i; i < _animationFrames.length; i++) {
         _animationFrames[i].imageStore = SSTORE2.write(_imageData[i]);
         animationFrames[_tokenId][frameNumber[i]] = _animationFrames[i];
      }
   }

   /// @notice IRREVERSIBLY SEALS THE CONTRACT FROM BEING MODIFIED
   function sealContract() external onlyDeployerWhileUnsealed {
      contractsealed = true;
   }
}
