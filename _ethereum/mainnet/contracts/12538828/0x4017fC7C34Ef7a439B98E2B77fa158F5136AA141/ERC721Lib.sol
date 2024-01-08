// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./IERC721LibBeforeTokenTransferHook.sol";

/* Functionality used to whitelist OpenSea trading address, if desired */

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, the Enumerable extension, and Pausable.
 *
 * Closely based on and mirrors the excellent https://openzeppelin.com/contracts/.
 */
library ERC721Lib {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    struct ERC721Storage {
        // Token name
        string _name;

        // Token symbol
        string _symbol;

        // Mapping from token ID to owner address
        mapping (uint256 => address) _owners;

        // Mapping owner address to token count
        mapping (address => uint256) _balances;

        // Mapping from token ID to approved address
        mapping (uint256 => address) _tokenApprovals;

        // Mapping from owner to operator approvals
        mapping (address => mapping (address => bool)) _operatorApprovals;

        // Mapping from owner to list of owned token IDs
        mapping(address => mapping(uint256 => uint256)) _ownedTokens;

        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) _ownedTokensIndex;

        // Array with all token ids, used for enumeration
        uint256[] _allTokens;

        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) _allTokensIndex;
        
        // Base URI
        string _baseURI;

        // True if token transfers are paused
        bool _paused;

        // Hook function that can be called before token is transferred, along with a pointer to its storage struct
        IERC721LibBeforeTokenTransferHook _beforeTokenTransferHookInterface;
        bytes32 _beforeTokenTransferHookStorageSlot;

        address proxyRegistryAddress;

    }

    function init(ERC721Storage storage s, string memory _name, string memory _symbol) external {
        s._name = _name;
        s._symbol = _symbol;
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId;
    }

    //
    // Start of ERC721 functions
    // 

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function _balanceOf(ERC721Storage storage s, address owner) internal view returns (uint256) {
        require(owner != address(0), "Balance query for address zero");
        return s._balances[owner];
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(ERC721Storage storage s, address owner) external view returns (uint256) {
        return _balanceOf(s, owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function _ownerOf(ERC721Storage storage s, uint256 tokenId) internal view returns (address) {
        address owner = s._owners[tokenId];
        require(owner != address(0), "Owner query for nonexist. token");
        return owner;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(ERC721Storage storage s, uint256 tokenId) external view returns (address) {
        return _ownerOf(s, tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name(ERC721Storage storage s) external view returns (string memory) {
        return s._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol(ERC721Storage storage s) external view returns (string memory) {
        return s._symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(ERC721Storage storage s, uint256 tokenId) external view returns (string memory) {
        require(_exists(s, tokenId), "URI query for nonexistent token");

        return bytes(s._baseURI).length > 0
            ? string(abi.encodePacked(s._baseURI, tokenId.toString()))
            : "";
    }

    /**
     * @dev Set base URI
     */
    function setBaseURI(ERC721Storage storage s, string memory baseTokenURI) external {
        s._baseURI = baseTokenURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(ERC721Storage storage s, address to, uint256 tokenId) external {
        address owner = _ownerOf(s, tokenId);
        require(to != owner, "Approval to current owner");

        require(msg.sender == owner || _isApprovedForAll(s, owner, msg.sender),
            "Not owner nor approved for all"
        );

        _approve(s, to, tokenId);
    }

    /**
     * @dev Approve independently of who's the owner
     *
     * Obviously expose with care...
     */
    function overrideApprove(ERC721Storage storage s, address to, uint256 tokenId) external {
        _approve(s, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function _getApproved(ERC721Storage storage s, uint256 tokenId) internal view returns (address) {
        require(_exists(s, tokenId), "Approved query nonexist. token");

        return s._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(ERC721Storage storage s, uint256 tokenId) external view returns (address) {
        return _getApproved(s, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(ERC721Storage storage s, address operator, bool approved) external {
        require(operator != msg.sender, "Attempted approve to caller");

        s._operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function _isApprovedForAll(ERC721Storage storage s, address owner, address operator) internal view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading - if we have a valid proxy registry address on file
        if (s.proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(s.proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return s._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(ERC721Storage storage s, address owner, address operator) external view returns (bool) {
        return _isApprovedForAll(s, owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(ERC721Storage storage s, address from, address to, uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(s, msg.sender, tokenId), "TransferFrom not owner/approved");

        _transfer(s, from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(ERC721Storage storage s, address from, address to, uint256 tokenId) external {
        _safeTransferFrom(s, from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function _safeTransferFrom(ERC721Storage storage s, address from, address to, uint256 tokenId, bytes memory _data) internal {
        require(_isApprovedOrOwner(s, msg.sender, tokenId), "TransferFrom not owner/approved");
        _safeTransfer(s, from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(ERC721Storage storage s, address from, address to, uint256 tokenId, bytes memory _data) external {
        _safeTransferFrom(s, from, to, tokenId, _data);
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
    function _safeTransfer(ERC721Storage storage s, address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(s, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "Transfer to non ERC721Receiver");
    }

    /**
     * @dev directSafeTransfer
     *
     * CAREFUL, this does not verify the previous ownership - only use if ownership/eligibility has been asserted by other means
     */
    function directSafeTransfer(ERC721Storage storage s, address from, address to, uint256 tokenId, bytes memory _data) external {
        _safeTransfer(s, from, to, tokenId, _data);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(ERC721Storage storage s, uint256 tokenId) internal view returns (bool) {
        return s._owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(ERC721Storage storage s, address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(s, tokenId), "Operator query nonexist. token");
        address owner = _ownerOf(s, tokenId);
        return (spender == owner || _getApproved(s, tokenId) == spender || _isApprovedForAll(s, owner, spender));
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
    function _safeMint(ERC721Storage storage s, address to, uint256 tokenId) internal {
        _safeMint(s, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(ERC721Storage storage s, address to, uint256 tokenId, bytes memory _data) internal {
        _unsafeMint(s, to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "Transfer to non ERC721Receiver");
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
    function _unsafeMint(ERC721Storage storage s, address to, uint256 tokenId) internal {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(s, tokenId), "Token already minted");

        _beforeTokenTransfer(s, address(0), to, tokenId);

        s._balances[to] += 1;
        s._owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(ERC721Storage storage s, uint256 tokenId) internal {
        address owner = _ownerOf(s, tokenId);

        _beforeTokenTransfer(s, owner, address(0), tokenId);

        // Clear approvals
        _approve(s, address(0), tokenId);

        s._balances[owner] -= 1;
        delete s._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(ERC721Storage storage s, address from, address to, uint256 tokenId) internal {
        require(_ownerOf(s, tokenId) == from, "TransferFrom not owner/approved");
        require(to != address(0), "Transfer to the zero address");

        _beforeTokenTransfer(s, from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(s, address(0), tokenId);

        s._balances[from] -= 1;
        s._balances[to] += 1;
        s._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(ERC721Storage storage s, address to, uint256 tokenId) internal {
        s._tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(s, tokenId), to, tokenId);
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non ERC721Receiver");
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

    //
    // Start of functions from ERC721Enumerable
    //

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(ERC721Storage storage s, address owner, uint256 index) external view returns (uint256) {
        require(index < _balanceOf(s, owner), "Owner index out of bounds");
        return s._ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function _totalSupply(ERC721Storage storage s) internal view returns (uint256) {
        return s._allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply(ERC721Storage storage s) external view returns (uint256) {
        return s._allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(ERC721Storage storage s, uint256 index) external view returns (uint256) {
        require(index < _totalSupply(s), "Global index out of bounds");
        return s._allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(ERC721Storage storage s, address from, address to, uint256 tokenId) internal {
        if(address(s._beforeTokenTransferHookInterface) != address(0)) {
            // We have a hook that we need to delegate call
            (bool success, ) = address(s._beforeTokenTransferHookInterface).delegatecall(
                abi.encodeWithSelector(s._beforeTokenTransferHookInterface._beforeTokenTransferHook.selector, s._beforeTokenTransferHookStorageSlot, from, to, tokenId)
            );
            if(!success) {
                // Bubble up the revert message
                assembly {
                    let ptr := mload(0x40)
                    let size := returndatasize()
                    returndatacopy(ptr, 0, size)
                    revert(ptr, size)
                }
            }
        }

        require(!_paused(s), "No token transfer while paused");

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(s, tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(s, from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(s, tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(s, to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(ERC721Storage storage s, address to, uint256 tokenId) private {
        uint256 length = _balanceOf(s, to);
        s._ownedTokens[to][length] = tokenId;
        s._ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(ERC721Storage storage s, uint256 tokenId) private {
        s._allTokensIndex[tokenId] = s._allTokens.length;
        s._allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(ERC721Storage storage s, address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _balanceOf(s, from) - 1;
        uint256 tokenIndex = s._ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s._ownedTokens[from][lastTokenIndex];

            s._ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            s._ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete s._ownedTokensIndex[tokenId];
        delete s._ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(ERC721Storage storage s, uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = s._allTokens.length - 1;
        uint256 tokenIndex = s._allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = s._allTokens[lastTokenIndex];

        s._allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        s._allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete s._allTokensIndex[tokenId];
        s._allTokens.pop();
    }

    //
    // Start of functions from Pausable
    //

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function _paused(ERC721Storage storage s) internal view returns (bool) {
        return s._paused;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(ERC721Storage storage s) external view returns (bool) {
        return s._paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused(ERC721Storage storage s) {
        require(!_paused(s), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused(ERC721Storage storage s) {
        require(_paused(s), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause(ERC721Storage storage s) external whenNotPaused(s) {
        s._paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause(ERC721Storage storage s) external whenPaused(s) {
        s._paused = false;
        emit Unpaused(msg.sender);
    }

}
