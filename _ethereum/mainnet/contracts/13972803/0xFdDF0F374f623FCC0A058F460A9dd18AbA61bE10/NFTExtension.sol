// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {

}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract NFTExtension is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;

  mapping(address => bool) internal admins;

  Counters.Counter internal _totalSupply;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  // Specifically whitelist an OpenSea proxy registry address.
  address public proxyRegistryAddress;

  modifier onlyAdmin() {
    require(admins[_msgSender()], 'Caller is not the admin');
    _;
  }

  /**
    An override to whitelist the OpenSea proxy contract to enable gas-free
    listings. This function returns true if `_operator` is approved to transfer
    items owned by `_owner`.
    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
  */
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }
    return super.isApprovedForAll(_owner, _operator);
  }

  // Function to grant admin role
  function addAdminRole(address _address) external onlyOwner {
    admins[_address] = true;
  }

  // Function to revoke admin role
  function revokeAdminRole(address _address) external onlyOwner {
    admins[_address] = false;
  }

  function hasAdminRole(address _address) external view returns (bool) {
    return admins[_address];
  }

  function _burn(uint256 tokenId) internal override(ERC721URIStorage) {
    super._burn(tokenId);
  }

  // Support Interface
  /*  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return super.supportsInterface(interfaceId);
  } */

  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
    require(index < balanceOf(owner), 'ERC721Enumerable: owner index out of bounds');
    return _ownedTokens[owner][index];
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from == address(0)) {
      _totalSupply.increment();
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }

    if (to == address(0)) {
      _totalSupply.decrement();
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply.current();
  }

  // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {}

  function burn(uint256 tokenId) external virtual {}

  function mint(uint256 _nbTokens, bool nftStaking) external payable virtual {}

  function evolve_mint(address _user) external virtual returns (uint256) {}
}
