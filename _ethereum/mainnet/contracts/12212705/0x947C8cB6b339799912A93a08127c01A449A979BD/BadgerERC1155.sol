// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./ERC1155TradeableUpgradeable.sol";
import "./PausableUpgradeable.sol";

/**
 * @title BadgerERC1155
 */
contract BadgerERC1155 is ERC1155TradeableUpgradeable, PausableUpgradeable {	
  string public contractURI;
  function initialize(address _proxyRegistryAddress, string memory uri) public initializer {
    _setBaseURI("https://badger.finance/nft/");
    contractURI = uri;
    __ERC1155Tradeable_init_unchained("BADGERNFT", "BNFT", _proxyRegistryAddress);
  }
  function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
    super.setApprovalForAll(operator, approved);
  }
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override whenNotPaused {
    super.safeTransferFrom(from, to, id, amount, data);
  }
  function safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override whenNotPaused {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
  function pause() public virtual onlyOwner {
    _pause();
  }
  function unpause() public virtual onlyOwner {
    _unpause();
  }
}
