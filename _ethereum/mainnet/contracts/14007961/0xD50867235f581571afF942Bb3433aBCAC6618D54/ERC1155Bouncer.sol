// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./AccessControl.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./Pausable.sol";
import "./OffchainBouncer.sol";

contract OwnableDelegateProxy { }

contract OSProxy {
  mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC1155Bouncer is OffchainBouncer, ERC1155, ERC1155Supply, ERC1155Burnable, Pausable {
  string name_;
  string symbol_; 

  address proxyRegistryAddress;

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }    

  /**
  * @notice change the base URI for the NFT
  *
  * @param baseURI the new NFT uri base
  */
  function setURI(string memory baseURI) external onlyOwner {
    _setURI(baseURI);
  }

  /**
  * @notice returns the metadata uri for a given id
  *
  * @param _id the NFT to return metadata for
  */
  function uri(uint256 _id) public view override returns (string memory) {
    require(exists(_id), "URI: nonexistent token");

    return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
  }

  // Required overrides
  function supportsInterface(bytes4 interfaceId) public view virtual override (AccessControl, ERC1155) returns (bool) {
    return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
  } 

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Supply) {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  /**
   * OpenSea gas-free listings.
   */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    OSProxy proxyRegistry = OSProxy(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }
}