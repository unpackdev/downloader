// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC2309.sol";
import "./IERC721LeanEnumerable.sol";
import "./ERC2981.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard.
 * Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 1 (e.g. 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC2309 is
    Context,
    ERC165,
    ERC2981,
    IERC721,
    IERC2309,
    IERC721Metadata,
    IERC721LeanEnumerable
{
    using Address for address;
    using Strings for uint256;

    struct AddressData {
        uint128 balance;
        uint128 minted;
    }

    // Base URI for metadata
    string public baseURI;
    
    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Track total tokens minted
    uint256 internal _totalSupply;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to address data
    mapping(address => AddressData) internal _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    error OwnerNotFound();
    error OwnerQueryForNonexistentToken();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error MintedQueryForZeroAddress();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToZeroAddress();
    error TokenIndexOutOfBounds();

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721LeanEnumerable).interfaceId ||
            super.supportsInterface(interfaceId)
        ;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _setBaseURI(string calldata newBaseURI) internal {
        baseURI = newBaseURI;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address wallet) public view virtual override returns (uint256) {
        require(wallet != address(0), "ERC721: balance query for the zero address");
        return uint256(_addressData[wallet].balance);
    }

    /**
     * @dev Returns the number of tokens minted by ``wallet``.
     */
    function mintedBy(address wallet) public view virtual returns (uint256) {
        if (wallet == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[wallet].minted);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), 'ERC721: owner query for nonexistent token');

        address tokenOwner = _owners[tokenId];
        unchecked {
            while (tokenOwner == address(0) && tokenId > 0) {
                tokenOwner = _owners[--tokenId];
            }
            
            if (tokenId == 0) revert OwnerNotFound();
        }

        return tokenOwner;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= _totalSupply;
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint128 quantity) internal {
        
        if (quantity == 0) revert MintZeroQuantity();
        if (to == address(0)) revert MintToZeroAddress();
        
        unchecked {

            uint256 nextTokenId = _totalSupply + 1;

            _totalSupply += quantity;
            _addressData[to].minted += quantity;
            _addressData[to].balance += quantity;
            _owners[nextTokenId] = to;

            emit ConsecutiveTransfer(nextTokenId, _totalSupply, address(0), msg.sender);
        }
    }

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
    function _transfer(address from, address to, uint256 tokenId) internal {
        address prevOwner = ownerOf(tokenId);

        if (to == address(0)) revert TransferToZeroAddress();
        if (prevOwner != from) revert TransferFromIncorrectOwner();
        
        _approve(address(0), tokenId);

        unchecked {

            _owners[tokenId] = to;
            _addressData[to].balance += 1;
            _addressData[from].balance -= 1;

            uint256 nextTokenId = tokenId + 1;
            if (_owners[nextTokenId] == address(0)) {
                if (_exists(nextTokenId)) {
                    _owners[nextTokenId] = prevOwner;
                }
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        uint256 tokenId = index + 1;
        if (tokenId > totalSupply()) revert TokenIndexOutOfBounds();
        return tokenId;
    }

/**
 ██████╗ ██████╗ ███████╗███╗   ██╗███████╗███████╗██████╗ ██████╗ ███████╗██╗     ██╗███╗   ██╗
██╔═══██╗██╔══██╗██╔════╝████╗  ██║╚══███╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██║     ██║████╗  ██║
██║   ██║██████╔╝█████╗  ██╔██╗ ██║  ███╔╝ █████╗  ██████╔╝██████╔╝█████╗  ██║     ██║██╔██╗ ██║
██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║ ███╔╝  ██╔══╝  ██╔═══╝ ██╔═══╝ ██╔══╝  ██║     ██║██║╚██╗██║
╚██████╔╝██║     ███████╗██║ ╚████║███████╗███████╗██║     ██║     ███████╗███████╗██║██║ ╚████║
 ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝     ╚═╝     ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝
 */                                                                                                                                  

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
}
