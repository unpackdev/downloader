
// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.17;

import "./ERC165.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";

import "./Address.sol";
import "./ContextUpgradeable.sol";

import "./Initializable.sol";

import "./ERC721BStorage.sol";

abstract contract ERC721BUpgradeable is Initializable, ContextUpgradeable, IERC165, IERC721Metadata {
  using ERC721BStorage for bytes32;

  // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC721")) - 1)) & ~bytes32(uint256(0xff))
  // solhint-disable-next-line const-name-snakecase
  bytes32 private constant ERC721StorageLocation = 0x80bb2b638cc20bc4d0a60d66940f3ab4a00c1d7b313497ca82fb0b4ab0079300;

  // Mapping owner address to Owner data
  // solhint-disable-next-line const-name-snakecase
  bytes32 private constant OwnerSlot = keccak256("OwnerSlot");

  // solhint-disable-next-line const-name-snakecase
  bytes32 internal constant TokenRangeSlot = keccak256("TokenRangeSlot");

  // Mapping from token ID to Token data
  // solhint-disable-next-line const-name-snakecase
  bytes32 internal constant TokenSlot = keccak256("TokenSlot");


  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  // solhint-disable-next-line func-name-mixedcase
  function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {

    ERC721Data storage data = ERC721StorageLocation.getERC721Storage();
    data._name = name_;
    data._symbol = symbol_;
  }

  function burnSupply() public view returns (uint256) {
    return owners(address(0)).balance;
  }

  function owners(address account) public view virtual returns (Owner memory) {
    return OwnerSlot.getOwnerStorage()._owners[account];
  }

  function range() public view virtual returns (TokenRange memory) {
    return TokenRangeSlot.getTokenRangeStorage()._range;
  }

  function tokens(uint256 tokenId) public view virtual returns (Token memory) {
    return TokenSlot.getTokenStorage()._tokens[tokenId];
  }

  function totalSupply() public view virtual returns (uint256) {
    return TokenRangeSlot.getTokenRangeStorage()._range.minted - burnSupply();
  }


  //public view
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId;
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "ERC721: address zero is not a valid owner");
    return owners(owner).balance;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _ownerOf(tokenId);
    require(owner != address(0), "ERC721: invalid token ID");
    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return ERC721StorageLocation.getERC721Storage()._name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return ERC721StorageLocation.getERC721Storage()._symbol;
  }



  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = _ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not token owner or approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return ERC721StorageLocation.getERC721Storage()._tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return ERC721StorageLocation.getERC721Storage()._operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    _safeTransfer(from, to, tokenId, data);
  }


  //internal
  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view returns (address) {
    return tokens(tokenId).owner;
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _ownerOf(tokenId) != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    address owner = _ownerOf(tokenId);
    return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
    _mintSequential(to, uint16(tokenId), 1, true);
    require(
      _checkOnERC721Received(address(0), to, tokenId, data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  function _mintSequential(address recipient, uint16 quantity, bool isPurchase) internal{
    _mintSequential(recipient, range().current, quantity, isPurchase);
  }

  function _mintSequential(address to, uint16 tokenId, uint16 quantity, bool isPurchase) internal {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId, quantity);

    _updateOwner(address(0), to, quantity, isPurchase);

    uint16 endTokenId = tokenId + quantity;
    TokenRangeContainer storage container = TokenRangeSlot.getTokenRangeStorage();
    unchecked{
      TokenRange memory prev = container._range;
      container._range = TokenRange(
        tokenId < prev.lower ? tokenId : prev.lower,
        endTokenId,
        endTokenId > prev.upper ? endTokenId - 1 : prev.upper,
        prev.minted + quantity
      );
    }

    for(; tokenId < endTokenId; ++tokenId){
      _transferToken(address(0), to, tokenId);
    }
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint16 tokenId) internal virtual {
    _transfer(_ownerOf(tokenId), address(0), tokenId);
  }


  /**
   * @dev Transfers `tokenId` from `from` to `to` and updates the owner's balance.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address from, address to, uint256 tokenId) internal {
    _updateOwner(from, to, 1, false);
    _transferToken(from, to, tokenId);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Emits a {Transfer} event.
   */
  function _transferToken(address from, address to, uint256 tokenId) internal {
    require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

    _beforeTokenTransfer(from, to, tokenId, 1);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
    require(_ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

    // Clear approvals from the previous owner
    ERC721Data storage data = ERC721StorageLocation.getERC721Storage();
    delete data._tokenApprovals[tokenId];

    TokenContainer storage container = TokenSlot.getTokenStorage();
    Token memory prev = container._tokens[tokenId];
    if(to == address(0)){
      container._tokens[tokenId] = Token(
        address(0),
        true, //isBurned
        false //isLocked
      );
    }
    else{
      container._tokens[tokenId] = Token(
        to,
        false, //isBurned
        prev.isLocked //isLocked
      );
    }

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    ERC721StorageLocation.getERC721Storage()._tokenApprovals[tokenId] = to;
    emit Approval(_ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    require(owner != operator, "ERC721: approve to caller");
    ERC721StorageLocation.getERC721Storage()._operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "ERC721: invalid token ID");
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns( bool ){
    if (to.code.length > 0) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          // solhint-disable-next-line no-inline-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }


  function _next() internal virtual returns(uint256 current){
    return range().current;
  }

  function _updateOwner(address from, address to, uint16 quantity, bool isPurchase) internal {
    Owner memory prev;

    mapping(address => Owner) storage _owners = OwnerSlot.getOwnerStorage()._owners;
    if(from != address(0)){
      prev = _owners[from];
      unchecked{
        _owners[from] = Owner(
          prev.balance - quantity,
          prev.purchased
        );
      }
    }

    prev = _owners[to];
    unchecked{
      _owners[to] = Owner(
        prev.balance + quantity,
        isPurchase ? prev.purchased + quantity : prev.purchased
      );
    }
  }


  /**
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}


  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[44] private __gap;
}
