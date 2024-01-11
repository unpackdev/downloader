//	SPDX-License-Identifier: MIT
/// @title  Logo Descriptor
/// @notice Descriptor which allow configuratin of logo containers and fetching of on-chain assets

pragma solidity ^0.8.0;

import "./LogoFactory.sol";
import "./SvgEmoticonComposer.sol";
import "./SvgText.sol";
import "./Ownable.sol";

interface INft {
  function ownerOf(uint256 tokenId) external view returns (address);
}

contract EmoticonLogoElementDescriptor is Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  address public nftAddress;
  INft nft;

  /// @notice Approved font links that can be used for logo layers
  mapping(string => bool) public approvedFontLinks;

  mapping(uint256 => string) public txtVals;
  mapping(uint256 => SvgText.Font) public txtFonts;

  modifier onlyWhileUnsealed() {
    require(!contractSealed, "Contract is sealed");
    _;
  }

  constructor(address _nftAddress) Ownable() {
    nftAddress = _nftAddress;
    nft = INft(_nftAddress);
  }

  /// @notice Sets approved font links which can be used for text
  /// @param fontLinks, links of fonts that can be used for text
  function setApprovedFontLinks(string[] memory fontLinks) external onlyWhileUnsealed onlyOwner {
    for(uint i; i < fontLinks.length; i++) {
      approvedFontLinks[fontLinks[i]] = true;
    }
  }

  /// @notice Sets unapproved font links which can be used for text
  /// @param fontLinks, links of fonts that cannot be used for text
  function setUnapprovedFontLinks(string[] memory fontLinks) external onlyWhileUnsealed onlyOwner {
    for(uint i; i < fontLinks.length; i++) {
      approvedFontLinks[fontLinks[i]] = false;
    }
  }

  /// @notice Gets the SVG for the logo layer
  /// @dev Required for any element used for a logo layer
  /// @param tokenId, the tokenId that SVG will be fetched for
  function getSvg(uint256 tokenId) public view returns (string memory) {
    SvgText.Font memory font = !LogoHelper.equal(txtFonts[tokenId].name, '') ? txtFonts[tokenId] : SvgText.Font('', 'Helvetica');
    return getSvg(tokenId, !LogoHelper.equal(txtVals[tokenId], '') ? txtVals[tokenId] : 'HELLO WORLD', font.name, font.link);
  }

  function getSvg(uint256 tokenId, string memory txt, string memory font, string memory fontLink) public view returns (string memory) {
    uint256 seed = LogoHelper.randomFromInt(tokenId);
    txt = isTxtAllowed(txt) ? txt: 'HELLO WORLD';
    SvgEmoticonBuilder.Emoticon memory emoticon = LogoFactory.initEmoticon(tokenId, seed, txt, SvgText.Font(fontLink, font));
    SvgEmoticonComposer.SvgDescriptor memory svg = SvgEmoticonComposer.SvgDescriptor(LogoHelper.toString(seed), '', emoticon);
    svg = SvgEmoticonComposer.getSvg(svg);
    return svg.svgVal;
  }

  function getSvgFromSeed(uint256 seed, string memory txt, string memory font, string memory fontLink) public view returns (string memory) {
    txt = isTxtAllowed(txt) ? txt: 'HELLO WORLD';
    SvgEmoticonBuilder.Emoticon memory emoticon = LogoFactory.initEmoticon(seed, seed, txt, SvgText.Font(fontLink, font));
    SvgEmoticonComposer.SvgDescriptor memory svg = SvgEmoticonComposer.SvgDescriptor(LogoHelper.toString(seed), '', emoticon);
    svg = SvgEmoticonComposer.getSvg(svg);
    return svg.svgVal;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    string memory json = LogoHelper.encode(abi.encodePacked('{"name": "Logo Emoticon #', LogoHelper.toString(tokenId), '", "description": "On-chain SVG emoticons.", "image": "data:image/svg+xml;base64,', LogoHelper.encode(bytes(getSvg(tokenId))), '", "attributes": ', getAttributes(tokenId),'}'));
    string memory output = string(abi.encodePacked('data:application/json;base64,', json));
    return output;
  }

  function getAttributes(uint256 tokenId) public view returns (string memory) {
    uint256 seed = LogoHelper.randomFromInt(tokenId);
    SvgEmoticonBuilder.Emoticon memory emoticon = LogoFactory.initEmoticon(tokenId, seed, 'hello world', !LogoHelper.equal(txtFonts[tokenId].name, '') ? txtFonts[tokenId] : SvgText.Font('', 'Helvetica'));
    return getFgAttributes(emoticon);
  }

  function getFgAttributes(SvgEmoticonBuilder.Emoticon memory emoticon) public pure returns (string memory) {
    string memory attributes = string(abi.encodePacked('{"trait_type": "Type", "value": "', emoticon.emoticonType, '"}, '));
    attributes = string(abi.encodePacked(attributes, '{"trait_type": "Palette", "value": "', emoticon.paletteName, '"}, '));
    string memory animated = emoticon.animate ? 'True' : 'False';
    return string(abi.encodePacked('[', attributes, '{"trait_type": "Animated", "value": "', animated, '"}]'));
  }

  function setTxtVal(uint256 tokenId, string memory val) public {
    require(tx.origin == nft.ownerOf(tokenId), 'Need to own token');
    txtVals[tokenId] = val;
  }

  function setFont(uint256 tokenId, string memory link, string memory font) public {
    require(tx.origin == nft.ownerOf(tokenId), 'Need to own token');
    require(approvedFontLinks[link], 'Not an approved font link');
    txtFonts[tokenId] = SvgText.Font(link, font);
  }

  function isTxtAllowed(string memory val) public pure returns (bool) {
    bytes memory b = bytes(val);
    // not longer than 25 bytes
    if (b.length > 25) {
      return false;
    }
    // is alphanumeric
    for (uint i; i < b.length; i++) {
      bytes1 char = b[i];
      if(!(char >= 0x30 && char <= 0x39) // 9-0
          && !(char >= 0x41 && char <= 0x5A) // A-Z
          && !(char >= 0x61 && char <= 0x7A) // a-z
          && !(char == 0x20) // space
          )
        { 
        return false;
      }
    }
    return true;
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
  }
}