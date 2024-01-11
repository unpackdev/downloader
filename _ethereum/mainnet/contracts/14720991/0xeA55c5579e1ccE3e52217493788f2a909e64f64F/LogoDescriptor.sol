//	SPDX-License-Identifier: MIT
/// @title  Logo Descriptor
/// @notice Descriptor which allow configuratin of logo containers and fetching of on-chain assets
pragma solidity ^0.8.0;

import "./LogoHelper.sol";
import "./LogoModel.sol";
import "./SvgElement.sol";
import "./SvgHeader.sol";
import "./Ownable.sol";

interface ILogoElementProvider {
  function mustBeOwnerForLogo() external view returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function getSvg(uint256 tokenId) external view returns (string memory);
  function getSvg(uint256 tokenId, string memory txt, string memory font, string memory fontLink) external view returns (string memory);
  function setTxtVal(uint256 tokenId, string memory val) external;
  function setFont(uint256 tokenId, string memory link, string memory font) external;
}

interface ILogos {
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface INftDescriptor {
  function namePrefix() external view returns (string memory);
  function description() external view returns (string memory);
  function getAttributes(Model.Logo memory logo) external view returns (string memory);
}

contract LogoDescriptor is Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  address public logosAddress;
  ILogos nft;

  address public nftDescriptorAddress;
  INftDescriptor nftDescriptor;

  /// @notice Boolean which sets whether or not only approved contracts can be used for logo layers
  bool public onlyApprovedContracts;

  /// @notice Approved contracts that can be used for logo layers
  mapping(address => bool) public approvedContracts;

  mapping(uint256 => Model.Logo) public logos;
  mapping(uint256 => mapping(string => string)) public metaData;

  modifier onlyWhileUnsealed() {
    require(!contractSealed, 'Contract is sealed');
    _;
  }

  modifier onlyLogoOwner(uint256 tokenId) {
    require(msg.sender == nft.ownerOf(tokenId), 'Only logo owner can be caller');
    _;
  }

  constructor(address _logosAddress, address _nftDescriptorAddress) Ownable() {
    logosAddress = _logosAddress;
    nft = ILogos(logosAddress);

    nftDescriptorAddress = _nftDescriptorAddress;
    nftDescriptor = INftDescriptor(nftDescriptorAddress);

    onlyApprovedContracts = true;
  }

  /// @notice Sets the address of the nft descriptor contract
  function setDescriptorAddress(address _address) external onlyOwner onlyWhileUnsealed {
    nftDescriptorAddress = _address;
    nftDescriptor = INftDescriptor(_address);
  }

  /// @notice Toggles whether or not only approved contracts can be used for logo layers
  function toggleOnlyApprovedContracts() external onlyOwner onlyWhileUnsealed {
    onlyApprovedContracts = !onlyApprovedContracts;
  }

  /// @notice Sets approved contracts which can be used for logo layers
  /// @param addresses, addresses of contracts that can be used for logo layers
  function setApprovedContracts(address[] memory addresses) external onlyOwner onlyWhileUnsealed {
    for(uint i; i < addresses.length; i++) {
      approvedContracts[addresses[i]] = true;
    }
  }

  /// @notice Unapproves a previously approved contract for logo layers
  /// @param addresses, addresses of contracts that cannot be used for logo layers
  function setUnapprovedContracts(address[] memory addresses) external onlyOwner onlyWhileUnsealed {
    for(uint i; i < addresses.length; i++) {
      approvedContracts[addresses[i]] = false;
    }
  }

  /// @notice Sets an individual logo layer
  /// @param tokenId, logo tokenId to set layer for
  /// @param layerIndex, array index of layer to set, use max uint256 for text element
  /// @param element, the new logo element
  /// @param txt, text to use for the text element of the logo, optional -  Only needed for text layer
  /// @param font, font to use for the text element of the logo, optional - use emptry string for default or non text layer
  /// @param fontLink, a url with the font specification for the chosen font, optional - use emptry string for default or non text layer
  function setLogoElement(uint256 tokenId, uint256 layerIndex, Model.LogoElement memory element, string memory txt, string memory font, string memory fontLink) public onlyLogoOwner(tokenId) {
    require(canSetElement(element.contractAddress, element.tokenId), 'Contract not approved or ownership requirements not met');
    Model.Logo storage sLogo = logos[tokenId];
    if (layerIndex == type(uint8).max) {
      sLogo.text = element;
      if (element.contractAddress != address(0x0) && !LogoHelper.equal(font, '')) {
        ILogoElementProvider provider = ILogoElementProvider(element.contractAddress);
        provider.setFont(element.tokenId, fontLink, font);
      } 
      if (element.contractAddress != address(0x0) && !LogoHelper.equal(txt, '')) {
        ILogoElementProvider provider = ILogoElementProvider(element.contractAddress);
        provider.setTxtVal(element.tokenId, txt);
      }
    } else {
      if (layerIndex >= sLogo.layers.length) {
        sLogo.layers.push(element);
      } else {
        sLogo.layers[layerIndex] = element;
      }
    }
  }

  /// @notice Sets logo visual attributes
  /// @notice Will not remove existing layers if new layers at index are not specified
  /// @notice To remove layers, the client should set the layer at index to null address
  /// @param tokenId, number of logo containers to mint
  /// @param logo, configuration of the logo container, see Logo struct
  /// @param txt, text to use for the text element of the logo
  /// @param font, font to use for the text element of the logo, optional - use emptry string for default
  /// @param fontLink, a url with the font specification for the chosen font, optional - use emptry string for default
  function setLogo(uint256 tokenId, Model.Logo memory logo, string memory txt, string memory font, string memory fontLink) external onlyLogoOwner(tokenId) {
    // set layers
    for (uint i; i < logo.layers.length; i++) {
      setLogoElement(tokenId, i, logo.layers[i], '', '', '');
    }
    // set text
    setLogoElement(tokenId, type(uint8).max, logo.text, txt, font, fontLink);
    Model.Logo storage sLogo = logos[tokenId];
    sLogo.width = logo.width;
    sLogo.height = logo.height;
  }

  /// @notice Contracts used for layers specify whether or not the layer can be used by non-owners of the token
  function canSetElement(address contractAddress, uint256 tokenId) public view returns (bool) {
    if (contractAddress == address(0x0)) {
      return true;
    }

    if (onlyApprovedContracts && !approvedContracts[contractAddress]) {
      return false;
    }

    ILogoElementProvider provider = ILogoElementProvider(contractAddress);
    if (provider.mustBeOwnerForLogo()) {
      return provider.ownerOf(tokenId) == msg.sender;
    }
    return true;
  }

  /// @notice Sets logo data
  /// @param tokenId, logo container tokenId
  /// @param _metaData, metadata to set for the specified logo
  function setMetaData(uint256 tokenId, Model.MetaData[] memory _metaData) external onlyLogoOwner(tokenId) {
    mapping(string => string) storage metaDataForToken = metaData[tokenId];
    for (uint256 i = 0; i < _metaData.length; i++) {
      metaDataForToken[_metaData[i].key] = _metaData[i].value;
    }
  }

  /// @notice Returns metadata for a list of keys
  /// @param tokenId, tokenId to return metadata for
  /// @param keys, keys of the metadata that values will be returned for
  function getMetaDataForKeys(uint tokenId, string[] memory keys) public view returns (string[] memory) {
    string[] memory values = new string[](keys.length);
    for (uint i; i < keys.length; i++) {
      values[i] = metaData[tokenId][keys[i]];
    }
    return values;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    string memory svg = getSvg(tokenId);
    string memory name = string(abi.encodePacked(nftDescriptor.namePrefix(), LogoHelper.toString(tokenId)));
    string memory json = LogoHelper.encode(abi.encodePacked('{"name": "', name, '", "description": "', nftDescriptor.description(), '", "image": "data:image/svg+xml;base64,', LogoHelper.encode(bytes(svg)), '", "attributes": ', nftDescriptor.getAttributes(logos[tokenId]),'}'));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  /// @notice Fetches attributes of logo
  /// @param tokenId, logo container tokenId
  function getAttributes(uint256 tokenId) external view returns (string memory) {
    return nftDescriptor.getAttributes(logos[tokenId]);
  }

  /// @notice Fetches text of the logo container
  /// @param tokenId, logo container tokenId
  function getTextElement(uint256 tokenId) external view returns (Model.LogoElement memory) {
    return logos[tokenId].text;
  }

  /// @notice Fetches layers of the logo container
  /// @param tokenId, logo container tokenId
  function getLayers(uint256 tokenId) external view returns (Model.LogoElement[] memory) {
    return logos[tokenId].layers;
  }

  /// @notice Returns svg of a specified logo
  /// @param tokenId, logo container tokenId
  function getSvg(uint256 tokenId) public view returns (string memory) {
    return getLogoSvg(logos[tokenId], '', '', '');
  }

  /// @notice Returns svg of a logo with given configuration, used for preview purposes
  /// @param logo, configuration of logo which svg should be generated
  /// @param overrideTxt, text to use for the text element of the logo
  /// @param overrideFont, font to use for the text element of the logo, optional - use emptry string for default
  /// @param overrideFontLink, a url with the font specification for the chosen font, optional - use emptry string for default
  function getLogoSvg(Model.Logo memory logo, string memory overrideTxt, string memory overrideFont, string memory overrideFontLink) public view returns (string memory) {
    string memory svg = SvgHeader.getHeader(logo.width, logo.height);

    ILogoElementProvider provider;
    Model.LogoElement memory element;
    for (uint i; i < logo.layers.length; i++) {
      element = logo.layers[i];
      if (element.contractAddress != address(0x0)) {
        provider = ILogoElementProvider(element.contractAddress);
        svg = string(abi.encodePacked(svg, SvgElement.getGroup(SvgElement.Group(getTransform(element), provider.getSvg(element.tokenId)))));
      }
    }

    element = logo.text;
    if (element.contractAddress != address(0x0)) {
      provider = ILogoElementProvider(element.contractAddress);
      if (!LogoHelper.equal(overrideTxt, '') || !LogoHelper.equal(overrideFont, '') || !LogoHelper.equal(overrideFontLink, '') ) {
        svg = string(abi.encodePacked(svg, SvgElement.getGroup(SvgElement.Group(getTransform(element), provider.getSvg(element.tokenId, overrideTxt, overrideFont, overrideFontLink)))));
      } else {
        svg = string(abi.encodePacked(svg, SvgElement.getGroup(SvgElement.Group(getTransform(element), provider.getSvg(element.tokenId)))));
      }
    }
    return string(abi.encodePacked(svg, '</svg>'));
  }

  /// @dev Gets svg transform element for the specified transform of the logo
  function getTransform(Model.LogoElement memory element) public pure returns (string memory) {
    return SvgHeader.getTransform(element.translateXDirection, element.translateX, element.translateYDirection, element.translateY, element.scaleDirection, element.scaleMagnitude);
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
  }
}

