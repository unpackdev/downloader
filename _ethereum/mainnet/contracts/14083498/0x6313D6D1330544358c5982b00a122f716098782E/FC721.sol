
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

/****************************************
 * @author: squeebo_nft                 *
 * @team:   GoldenX                     *
 ****************************************
 *   Blimpie-ERC721 provides low-gas     *
 *       mints + transfers              *
 ****************************************/

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";


abstract contract FC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;

  struct Token{
    address owner;
    uint16 points;
  }

  Token[] public tokens;
  mapping(address => uint[]) public balances;

  string private _name;
  string private _symbol;

  mapping(uint => address) internal _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_){
    _name = name_;
    _symbol = symbol_;
  }

  //public view
  function balanceOf(address owner) public view override returns (uint balance){
    return balances[owner].length;
  }

  function name() external view override returns( string memory name_ ){
    return _name;
  }

  function ownerOf(uint tokenId) public view override returns( address owner ){
    require(_exists(tokenId), "FC721: query for nonexistent token");
    return tokens[tokenId].owner;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns( bool isSupported ){
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function symbol() external view override returns( string memory symbol_ ){
    return _symbol;
  }


  //approvals
  function approve(address to, uint tokenId) external override {
    address owner = ownerOf(tokenId);
    require(to != owner, "FC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "FC721: caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  function getApproved(uint tokenId) public view override returns( address approver ){
    require(_exists(tokenId), "FC721: query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function isApprovedForAll(address owner, address operator) public view override returns( bool isApproved ){
    return _operatorApprovals[owner][operator];
  }

  function setApprovalForAll(address operator, bool approved) external override {
    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }


  //transfers
  function safeTransferFrom(address from, address to, uint tokenId) external override{
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "FC721: caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  function transferFrom(address from, address to, uint tokenId) external override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "FC721: caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }


  //internal
  function _approve(address to, uint tokenId) internal{
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual {
      if( from != address(0) ){
        uint length = balances[from].length;
        for( uint i; i < length; ++i ){
          if( balances[from][i] == tokenId ){
            balances[from][i] = balances[from][length - 1];
            balances[from].pop();
            break;
          }
        }
      }

      if( to != address(0) )
        balances[to].push( tokenId );
    }

  function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory _data)private returns ( bool ){
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("FC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _exists(uint tokenId) internal view returns ( bool ){
    return tokenId < tokens.length && tokens[tokenId].owner != address(0);
  }

  function _isApprovedOrOwner(address spender, uint tokenId) internal view returns( bool ){
    require(_exists(tokenId), "FC721: query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal{
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "FC721: transfer to non ERC721Receiver implementer");
  }

  function _transfer(address from, address to, uint tokenId) internal {
    require(ownerOf(tokenId) == from, "FC721: transfer of token that is not own");
    _beforeTokenTransfer( from, to, tokenId );

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);
    tokens[tokenId].owner = to;

    emit Transfer(from, to, tokenId);
  }
}
