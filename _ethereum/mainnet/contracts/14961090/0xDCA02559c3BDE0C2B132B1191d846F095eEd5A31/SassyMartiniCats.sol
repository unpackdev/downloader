// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./ReentrancyGuard.sol";

  error ApprovalCallerNotOwnerNorApproved();
  error ApprovalQueryForNonexistentToken();
  error ApproveToCaller();
  error ApprovalToCurrentOwner();
  error BalanceQueryForZeroAddress();
  error TransferCallerNotOwnerNorApproved();
  error TransferFromIncorrectOwner();
  error TransferToNonERC721ReceiverImplementer();
  error TransferToZeroAddress();
  error URIQueryForNonexistentToken();
  error RoyaltyInfoForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 * Makes use of some erc721a gas efficiency improvements. See https://www.erc721a.org/ for more info about erc721a.
 * Also builds on https://github.com/hashlips-lab/nft-erc721-collection
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
*/
contract SassyMartiniCats is IERC721, Context, ERC165, IERC721Metadata, IERC2981, Ownable, ReentrancyGuard {
  using Address for address;
  using Strings for uint256;

  // Compiler will pack this into a single 256bit word.
  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
  }

  // Compiler will pack this into a single 256bit word.
  struct AddressData {
    // Realistically, 2**64-1 is more than enough.
    uint64 balance;
    // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberMinted;
    // Keeps track of burn count with minimal overhead for tokenomics.
    uint64 numberBurned;
    // For miscellaneous variable(s) pertaining to the address
    // (e.g. number of whitelist mint slots used).
    // If there are multiple variables, please pack them into a uint64.
    uint64 aux;
  }

  // Token name
  string private _name = "SassyMartiniCats";

  // Token symbol
  string private _symbol = "SMC";

  // Mapping from token ID to owner address
  mapping(uint256 => TokenOwnership) public owners;

  // Mapping owner address to address data
  mapping(address => AddressData) public addressData;
  // Mapping owner address to token count
  //mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  uint256 public mintPrice = 0.06 ether;
  bool public isPaused = true;
  string public uriPrefix = "ipfs://QmdotcAMWS8ENYngZwUCDnsxgaDz7gm7u2p2hastGj59Pb/";
  string public uriSuffix = '.json';
  uint256 public maxToken = 10100;

  constructor(
    //string memory name_,
    //string memory symbol_,
    //string memory _uriPrefix
  ) {
    //_name = name_;
    //_symbol = symbol_;
    //uriPrefix = _uriPrefix;
  }

  function toggleIsEnabled() external onlyOwner {
    isPaused = !isPaused;
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
  function _safeMint(address to, uint256 tokenId) private {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private {
    _mint(to, tokenId);
//    require(
//      _checkContractOnERC721Received(address(0), to, tokenId, _data),
//      "ERC721: transfer to non ERC721Receiver implementer"
//    ); //TODO will this always fail in the unit test?
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
  function _mint(address to, uint256 tokenId) private {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    addressData[to].balance += 1;
    addressData[to].numberMinted += 1;

    owners[tokenId].addr = to;
    owners[tokenId].startTimestamp = uint64(block.timestamp);

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  function mintCat(uint256 tokenId) external payable nonReentrant {
    require(_msgSender() != address(this), "SMC: No sending to this contract");
    require(_msgSender() == tx.origin, "SMC: Contract Interaction Not Allowed");
    require(!isPaused, 'SMC: Contract is Paused');
    require(msg.value >= mintPrice, 'SMC: Price too low');
    require(tokenId != 0, "SMC: Can't mint invalid token");
    require(tokenId <= maxToken, "SMC: Can't mint invalid token");

    _safeMint(_msgSender(), tokenId);
  }

  //TODO should I change this to be offset (start index) + length to mint?
  function initialMint(uint256 offset, uint256 length) public nonReentrant onlyOwner {
    uint256 curr = 9001 + offset * length;
    uint256 top = curr + length;
    require(maxToken + 1 >= top, "SMC: Cannot mint");

    while(curr < top) {
      _safeMint(owner(), curr);
      curr++;
    }
  }

  function gift(uint256 tokenId, address destination) public onlyOwner {
    require(destination != address(0x0), "ERC721: mint to the zero address");
    require(destination != address(this), "SMC: No sending to this contract");
    require(tokenId != 0, "SMC: Can't mint invalid token");
    require(tokenId <= maxToken, "SMC: Can't mint invalid token");

    _safeMint(destination, tokenId);
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, "SMC: Withdraw failed");
  }

  /**
   * @dev See {IERC721Metadata-name}.
     */
  function name() public view override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
     */
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
     */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    //if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    : '';
  }

  function _baseURI() internal view returns (string memory) {
    return uriPrefix;
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
    return
    interfaceId == type(IERC2981).interfaceId ||
    interfaceId == type(IERC721).interfaceId ||
    interfaceId == type(IERC721Metadata).interfaceId ||
    super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
     */
  function balanceOf(address owner) public view override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    return uint256(addressData[owner].balance);
  }

  /**
   * @dev See {IERC721-ownerOf}.
     */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    address owner = owners[tokenId].addr;
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IERC721-approve}.
     */
  function approve(address to, uint256 tokenId) public override {
    address owner = SassyMartiniCats.ownerOf(tokenId); //TODO does this explicit call still need to be like this?
    if (to == owner) revert ApprovalToCurrentOwner();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
     */
  function getApproved(uint256 tokenId) public view override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
     */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (operator == _msgSender()) revert ApproveToCaller();

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
     */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
     */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
     */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, '');
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
     */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    _transfer(from, to, tokenId);
    if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
      revert TransferToNonERC721ReceiverImplementer();
    }
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
    * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = owners[tokenId];
    //TODO does this need to make sure it's owned before initiating a transfer? should the reciever error be here?
    if (from == address (0)) revert TransferFromIncorrectOwner();
    if (prevOwnership.addr != from) revert TransferFromIncorrectOwner(); //from is set before the call to this function
    if (to == address(0)) revert TransferToZeroAddress();

    bool isApprovedOrOwner = (_msgSender() == from ||
    isApprovedForAll(from, _msgSender()) ||
    getApproved(tokenId) == _msgSender());

    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

  unchecked {
    addressData[from].balance -= 1;
    addressData[to].balance += 1;

    TokenOwnership storage currSlot = owners[tokenId];
    currSlot.addr = to;
    currSlot.startTimestamp = uint64(block.timestamp);
  }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return owners[tokenId].addr != address(0);
  }

  /**
   * @dev see {IERC2981-royaltyInfo}
     *
     * Royalty is linked to the contract owner with a 2.5 percent royalty.
     */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
    if (!_exists(_tokenId)) revert RoyaltyInfoForNonexistentToken();
    return (owner(), _salePrice * 25 / 1000);
  }

  function nextUnminted(uint256 startIndex) external view returns (uint256) {
    uint256 currentIndex = startIndex;

    while(currentIndex <= maxToken) {
      if(!_exists(currentIndex)) {
        break;
      }
      currentIndex++;
    }

    return currentIndex;
  }

  function updateMaxCount(uint256 newMax) external onlyOwner {
    if(newMax > maxToken) {
      maxToken = newMax;
    }
  }
}
