//	SPDX-License-Identifier: MIT
/// @title  Logo Descriptor
/// @notice Descriptor which allow configuratin of logo containers and fetching of on-chain assets

pragma solidity ^0.8.0;

import "./LogoFactory.sol";
import "./SvgBuilder.sol";

interface INft {
  function ownerOf(uint256 tokenId) external view returns (address);
}

struct Dimensions {
  uint16 width;
  uint16 height;
}

contract BackgroundLogoElementDescriptor {
  address public nftAddress;
  INft nft;

  /// @notice Non-default dimensions can be set for background
  mapping(uint256 => Dimensions) public dimensions;

  constructor(address _nftAddress) {
    nftAddress = _nftAddress;
    nft = INft(_nftAddress);
  }

  /// @notice Sets non-default dimensions for background
  /// @param width, the width to be used for the background
  /// @param height, the height to be used for the background
  function setDimensions(uint256 tokenId, uint16 width, uint16 height) public {
    require(msg.sender == nft.ownerOf(tokenId), 'Must be owner of background');
    dimensions[tokenId] = Dimensions(width, height);
  }

  /// @notice Gets the SVG for the logo layer
  /// @dev Required for any element used for a logo layer
  /// @param tokenId, the tokenId that SVG will be fetched for
  function getSvg(uint256 tokenId) public view returns (string memory) {
    uint256 seed = LogoHelper.randomFromInt(tokenId);
    SvgBackground.Background memory background = LogoFactory.initBackground(tokenId, seed);
    Dimensions memory bgDimensions = dimensions[tokenId];
    background.width = bgDimensions.width;
    background.height = bgDimensions.height;
    SvgBackgroundBuilder.SvgDescriptor memory svg = SvgBackgroundBuilder.SvgDescriptor(LogoHelper.toString(seed), '', background);
    svg = SvgBackgroundBuilder.getSvg(svg);
    return svg.svgVal;
  }

  function getSvgFromSeed(uint256 seed) public view returns (string memory) {
    SvgBackground.Background memory background = LogoFactory.initBackground(seed, seed);
    SvgBackgroundBuilder.SvgDescriptor memory svg = SvgBackgroundBuilder.SvgDescriptor(LogoHelper.toString(seed), '', background);
    svg = SvgBackgroundBuilder.getSvg(svg);
    return svg.svgVal;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    string memory json = LogoHelper.encode(abi.encodePacked('{"name": "Logo Background #', LogoHelper.toString(tokenId), '", "description": "An experiment with shapes, color, distortion, and movement. On-chain generatative SVG.", "image": "data:image/svg+xml;base64,', LogoHelper.encode(bytes(getSvg(tokenId))), '", "attributes": ', getAttributes(tokenId),'}'));
    string memory output = string(abi.encodePacked('data:application/json;base64,', json));
    return output;
  }

  function getAttributes(uint256 tokenId) public view returns (string memory) {
    uint256 seed = LogoHelper.randomFromInt(tokenId);
    SvgBackground.Background memory background = LogoFactory.initBackground(tokenId, seed);
    return getBgAttributes(background);
  }

  function getAttributesFromSeed(uint256 seed) public view returns (string memory) {
    SvgBackground.Background memory background = LogoFactory.initBackground(0, seed);
    return getBgAttributes(background);
  }

  function getBgAttributes(SvgBackground.Background memory background) public pure returns (string memory) {
    string memory attributes = string(abi.encodePacked('{"trait_type": "Type", "value": "', background.backgroundType, '"}, '));
    attributes = string(abi.encodePacked(attributes, '{"trait_type": "Filter", "value": "', background.filter.filterType, '"}, '));
    attributes = string(abi.encodePacked(attributes, '{"trait_type": "Palette", "value": "', background.paletteName, '"}, '));
    string memory animated = "False";
    for (uint8 i = 0; i < background.fills.length; i++) {
      if (background.fills[i].animate == true) {
        animated = "True";
        break;
      }
    }
    if (background.filter.animate == true) {
      animated = "True";
    }
    return string(abi.encodePacked('[', attributes, '{"trait_type": "Animated", "value": "', animated, '"}]'));
  }
}