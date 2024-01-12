// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./TokenBridgeUpgradeable.sol";

contract TokenBridgeUpgradeableV2 is
  TokenBridgeUpgradeable
{
  event Transfer(bytes4 interfaceId, address indexed tokenAddress, address indexed from, address indexed to, uint256 tokenId, uint256 amount);

  /***
   * Public functions
   */
  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public virtual override(TokenBridgeUpgradeable) returns (bytes4) {
    address tokenAddress = msg.sender;
    address to = address(this);
    uint256 amount = 1;
    emit Transfer(INTERFACE_ID_IERC721, tokenAddress, from, to, tokenId, amount);
    
    return super.onERC721Received(operator, from, tokenId, data);
  }

  function onERC1155Received(address operator, address from, uint256 tokenId, uint256 amount, bytes memory data) public virtual override(TokenBridgeUpgradeable) returns (bytes4) {
    address tokenAddress = msg.sender;
    address to = address(this);
    emit Transfer(INTERFACE_ID_IERC1155, tokenAddress, from, to, tokenId, amount);
    
    return super.onERC1155Received(operator, from, tokenId, amount, data);
  }
  
  function exportTokenByModerator(bytes4 interfaceId, address tokenAddress, address to, uint256 tokenId, uint256 amount) public {
    require(hasRole(MODERATOR_ROLE, msg.sender), "TokenBridgeUpgradeable: must be moderator");

    _exportToken(interfaceId, tokenAddress, to, tokenId, amount);
  }
  
  function mintCollectibleToken(bytes4 interfaceId, address tokenAddress, uint256 tokenId, string memory nonce, uint256 expiration, bytes memory signature) public virtual override(TokenBridgeUpgradeable) {    
    super.mintCollectibleToken(interfaceId, tokenAddress, tokenId, nonce, expiration, signature);
    
    address from = address(0);
    address to = msg.sender;
    uint256 amount = 1;
    emit Transfer(interfaceId, tokenAddress, from, to, tokenId, amount);
  }
  
  function mintCollectibleTokenByModerator(bytes4 interfaceId, address tokenAddress, address to, uint256 tokenId) public virtual {
    require(hasRole(MODERATOR_ROLE, msg.sender), "TokenBridgeUpgradeable: must be moderator");
    
    CollectibleTokenUpgradeable(tokenAddress).mint(to, tokenId, "");
    
    address from = address(0);
    uint256 amount = 1;
    emit Transfer(interfaceId, tokenAddress, from, to, tokenId, amount);
  }

  /***
   * Internal functions
   */
  function _exportToken(bytes4 interfaceId, address tokenAddress, address to, uint256 tokenId, uint256 amount) internal virtual override(TokenBridgeUpgradeable) {
    super._exportToken(interfaceId, tokenAddress, to, tokenId, amount);
        
    address from = address(this);
    emit Transfer(interfaceId, tokenAddress, from, to, tokenId, amount);    
  }

}
