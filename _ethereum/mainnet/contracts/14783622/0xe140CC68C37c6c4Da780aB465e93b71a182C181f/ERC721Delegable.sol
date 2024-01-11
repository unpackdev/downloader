// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Delegable.sol";
import "./ERC721.sol";

/**
 * @title ERC721Delegable
 * @dev Implementation of the IERC721Delegable interface, extending the
 * {ERC721} non-fungible token standard with the addition of a delegate token.
 * @author 0xAnimist (kanon.art)
 */
abstract contract ERC721Delegable is ERC721, IERC721Delegable {

  struct Delegate {
    address contractAddress;
    uint256 tokenId;
  }

  // Mapping token ID to delegate token
  mapping(uint256 => Delegate) private _delegates;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
      return
        interfaceId == type(IERC721Delegable).interfaceId
        || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Delegable-setDelegateToken}.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId) public virtual override {
    setDelegateToken(_delegateContract, _delegateTokenId, _tokenId, "");
  }

  /**
   * @dev See {IERC721Delegable-setDelegateToken}.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId, bytes memory _data) public virtual override {
    require(_isDelegateOrOwnerOfUndelegated(_msgSender(), _tokenId), "ERC721Q: not authorized to set delegate");

    _delegates[_tokenId] = Delegate(_delegateContract, _delegateTokenId);

    emit DelegateTokenSet(_delegateContract, _delegateTokenId, _tokenId, _msgSender(), _data);
  }

  /**
   * @dev See {IERC721Delegable-getDelegateToken}.
   */
  function getDelegateToken(uint256 _tokenId) public view virtual override returns (address contractAddress, uint256 tokenId) {
    return (_delegates[_tokenId].contractAddress, _delegates[_tokenId].tokenId);
  }

  /**
   * @dev See {IERC721Delegable-approveByDelegate}.
   */
  function approveByDelegate(address to, uint256 tokenId) public virtual override {
      address owner = ERC721.ownerOf(tokenId);
      require(to != owner, "ERC721: approval to current owner");

      require(_msgSender() == _getDelegateOwner(tokenId),"ERC721: approve caller is not owner nor approved for all nor delegate");

      _approve(to, tokenId);
  }

  /**
   * @dev Returns true if `_operator` is the owner of the delegate token of `_tokenId
   * token or, if and only if the delegate token has not been set (ie. is address(0)),
   * returns true if `_operator` is the owner of `_tokenId` token.
   */
  function _isDelegateOrOwnerOfUndelegated(address _operator, uint256 _tokenId) internal view virtual returns (bool) {
    address delegate = _getDelegateOwner(_tokenId);
    if(delegate != address(0)){//delegate has been set
      return _operator == delegate;
    }else{//delegate has not been set
      return _operator == ownerOf(_tokenId);
    }
  }

  /**
   * @dev Returns owner of the delegate token for `_tokenId` token, or address(0) if
   * no delegate token has been set.
   *
   * Requirements:
   *
   * - tokenId must exist
   */
  function _getDelegateOwner(uint256 _tokenId) internal view returns (address delegateOwner) {
    require(_exists(_tokenId), "ERC721Q: token does not exist");

    if(_delegates[_tokenId].contractAddress != address(0)){//delegate has been set
      return IERC721(_delegates[_tokenId].contractAddress).ownerOf(_delegates[_tokenId].tokenId);//fails if delegate token has been burnt
    }

    return address(0);//delegate has not been set
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function _burn(uint256 tokenId) internal virtual override {
    setDelegateToken(address(0),0,tokenId);
    ERC721._burn(tokenId);
  }
}
