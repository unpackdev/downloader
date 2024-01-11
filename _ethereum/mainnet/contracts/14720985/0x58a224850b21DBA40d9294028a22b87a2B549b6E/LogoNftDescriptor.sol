//	SPDX-License-Identifier: MIT
/// @title  Logo Nft Descriptor
/// @notice Descriptor which allow configuratin of logo nft
pragma solidity ^0.8.0;

import "./LogoHelper.sol";
import "./LogoModel.sol";
import "./Ownable.sol";

contract LogoNftDescriptor is Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  string public namePrefix = 'DO NOT PURCHASE. Logo Container #'; 
  string public description = 'DO NOT PURCHASE. Logo containers point to other NFTs to create an image.'
                              ' Purchasing this NFT will not also purchase the NFTs creating the image.'
                              ' There is an infinite supply of logo containers and they can be minted for free.';

  modifier onlyWhileUnsealed() {
    require(!contractSealed, 'Contract is sealed');
    _;
  }

  constructor() Ownable() {}

  /// @notice Sets the prefix of a logo container name used by tokenURI
  /// @param _namePrefix, prefix to use for the logo container
  function setNamePrefix(string memory _namePrefix) external onlyOwner onlyWhileUnsealed {
    namePrefix = _namePrefix;
  }

  /// @notice Sets the description of a logo container name used by tokenUri
  /// @param _description, description to use for the logo container
  function setDescription(string memory _description) external onlyOwner onlyWhileUnsealed {
    description = _description;
  }

  /// @notice Gets attributes for attributes used in tokenURI
  function getAttributes(Model.Logo memory logo) public view returns (string memory) {
    string memory attributes;
    for (uint i; i < logo.layers.length; i++) {
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Layer #', LogoHelper.toString(i), ' Address", "value": "0x', LogoHelper.toString(logo.layers[i].contractAddress), '"}, '));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Layer #', LogoHelper.toString(i),  ' Token Id", "value": "', LogoHelper.toString(logo.layers[i].tokenId), '"}, '));
    }
    attributes = string(abi.encodePacked(attributes, '{"trait_type": "Text Address", "value": "0x', LogoHelper.toString(logo.text.contractAddress), '"}, '));
    attributes = string(abi.encodePacked('[', attributes, '{"trait_type": "Text Token Id", "value": "', LogoHelper.toString(logo.text.tokenId), '"}]'));
    return attributes;
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
  }
}