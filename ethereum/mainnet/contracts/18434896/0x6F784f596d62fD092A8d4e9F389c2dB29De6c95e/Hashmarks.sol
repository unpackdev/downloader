//
// █████████████████████████████████████████████████████████████████████████████████████████████████
// █████████████████████████████████████████████████████████████████████████████████████████████████
// ██████░  ▒████████████░    ▒███░      ▒████░▒████░      ▒█░     ▒██░      ▒█░      ▒█░      ▒████
// █████░ ▒░ ▒████████████░ ▒░ ▒███░ ▒█░ ▒███░  ▒████░ ▒█░ ▒██░ ▒█░ ▒██░ ▒█░ ▒██░ ▒█░ ▒██░ ▒█░ ▒████
// ████░ ▒██░ ▒███████████░ ▒█░ ▒██░ ▒██░▒██░ ▒░ ▒███░ ▒██░▒██░ ▒█░ ▒██░ ▒██░▒██░ ▒██░▒██░ ▒██░▒████
// ████░ ▒██░ ▒█░ ▒██░ ▒██░ ▒█░ ▒██░ ▒░▒███░ ▒██░ ▒██░ ▒░▒████░ ▒█░ ▒██░ ▒░▒████░ ▒░▒████░ ▒░▒██████
// ████░ ▒░▒░ ▒██░ ▒░ ▒███░ ▒█░ ▒██░   ▒███░ ▒██░ ▒██░   ▒████░    ▒███░   ▒████░   ▒████░   ▒██████
// ████░ ▒██░ ▒███░  ▒████░ ▒█░ ▒██░ ▒░▒███░      ▒██░ ▒░▒████░ ▒█░ ▒██░ ▒░▒████░ ▒░▒████░ ▒░▒██████
// ████░ ▒██░ ▒███░  ▒████░ ▒█░ ▒██░ ▒██░▒█░ ▒██░ ▒██░ ▒██████░ ▒█░ ▒██░ ▒██░▒██░ ▒██░▒██░ ▒████████
// █████░ ▒░ ▒███░ ▒░ ▒███░ ▒░ ▒███░ ▒░  ▒█░ ▒██░ ▒██░ ▒██████░ ▒█░ ▒██░ ▒░  ▒██░ ▒░  ▒██░ ▒████████
// ██████░  ▒███░ ▒██░ ▒█░    ▒███░      ▒█░ ▒██░ ▒█░   ▒████░     ▒██░      ▒█░      ▒█░   ▒███████
// █████████████████████████████████████████████████████████████████████████████████████████████████
// █████████████████████████████████████████████████████████████████████████████████████████████████
//
// HASHMARKS by 0xDEAFBEEF
// Oct 2023
//
// SPDX-License-Identifier: MIT

abstract contract DataContract {
  function data() external virtual view returns (bytes memory);
}

pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)




/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    //    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    string internal _baseURI;

    mapping(uint256 => string) internal _tokenURIs;
    
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
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
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    // On-chain metadata per token can optionally be stored in _tokenURIs[]
    // If it exists, use it. Otherwise use _baseURI concatenated with tokenId
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        if (bytes(_tokenURIs[tokenId]).length > 0) {
            return _tokenURIs[tokenId];
        }

        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, ToString.toString(tokenId))) : "";
    }

    

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        address owner = ERC721.ownerOf(tokenId);
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}



// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


pragma solidity ^0.8.4;

library ToString {
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
  
  bytes internal constant TABLE = "0123456789ABCDEF";    
  //returns hex byte value like 00 - ff
  function toHex(uint256 val) internal pure returns (string memory) {
    if (val==0) return "00";
      
    bytes memory buf = new bytes(2);
    buf[1] = TABLE[val & 0xf];
    buf[0] = TABLE[val >> 4 & 0xf];
    return string(buf);
  }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
//      return string(data);
      
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

contract Hashmarks is ERC721 {
  bool isSealed;
  address _owner;

  // H^11(secret) to claim, H^10.. H^1 for refreshes
  uint256 public constant max_hashes = 11;
  uint256 public constant fade_period = (86400*365); // 1 year

  /* image fades to this color; */
  uint256 public constant grey_fade = 0xc0;  
  
  uint256 public constant reveal_window = (86400*2); //48 hr

  /* safeguard allowlists for commit/reveal expire after 180 days,
     after which any address can perform commit/reveals */
  uint256 public constant safeguard_expire = 86400*180;
  
  uint256 public deployed_ts;
  uint256[100] fadeamounts;

  uint256 numTokens;

  struct TokenStruct {
    bool claimed;
    address claimer;
    
    uint256 hindex; //index into hashchain[]
    bytes32[100] hashchain;
    
    DataContract[2] paths; //svg paths
    uint256 last_refresh;
    uint256 period;    
    bool immortal;
  }

  struct CommitStruct {
    bytes32 hash;
    uint256 ts;
  }

  event eRefresh(uint256 tid,uint256 hindex);
  event eAscension(uint256 tid);
  event eClaim(uint256 tid);
  
  mapping(uint256 => TokenStruct) public tokens;
  mapping(address => CommitStruct) public commits;

  mapping(address => bool) public allow_commit; //safeguard allow list for address allowed to perform commits
  mapping(bytes32 => bool) public allow_reveal; //safeguard allow list for (address,token_id) eligible to be revealed


  //only performed by contract owner, before seal() is called
  modifier onlyInit() {
    require(msg.sender==_owner && isSealed == false);
    _;
  }

  //only performed by contract owner
  modifier onlyOwner() {
    require(msg.sender==_owner);
    _;
  }  

  constructor() ERC721("HASHMARKS", "HASHMARKS") {    
    deployed_ts = block.timestamp;
    _owner = msg.sender;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }
  
  function totalSupply() public view returns (uint256) {
    return numTokens;
  }
  
  function walletOfOwner(address a) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(a);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < 100) {
      if (_exists(currentTokenId)) {
	address currentTokenOwner = ownerOf(currentTokenId);
	if (currentTokenOwner == a) {
	  ownedTokenIds[ownedTokenIndex] = currentTokenId;
	  ownedTokenIndex++;
	}
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

    
  // Prevents any further admin updates to initHashes, initData, safeguard_addresses or safeguard_tokenids
  function seal() public onlyOwner {
    require(isSealed == false, "Already sealed.");
    isSealed = true;
  }
  
  function initHashes(uint256[] memory tid, bytes32[] memory a) public onlyInit {
    for (uint256 i = 0;i<tid.length;i++) {
      tokens[tid[i]].hashchain[0] = a[i];
    }
  }

  // Admin maintained safeguard list of addresses allowed to perform commits
  // Safeguard expires automatically after 180 days
  function safeguard_commit(address[] memory a, bool v) public onlyInit {
    for (uint256 i = 0;i<a.length;i++)
      allow_commit[a[i]] = v;
  }
  
  // Admin maintained safeguard list of (address,token id) pairs allowed to be revealed
  // Safeguard expires automatically after 180 days
  function safeguard_reveal(address[] memory a, uint256[] memory tid, bool v) public onlyInit {
    for (uint256 i = 0;i<tid.length;i++)
      allow_reveal[keccak256(abi.encodePacked(a[i],tid[i]))] = v;
  }

  // public read function for additional TokenStruct array fields 
  function tokenInfo(uint256 tid) public view returns(address[] memory paths, bytes32[] memory hashchain) {

    address[] memory plist = new address[](2);
    plist[0] = address(tokens[tid].paths[0]);
    plist[1] = address(tokens[tid].paths[1]);

    paths = plist;
    
    bytes32[] memory rlist = new bytes32[](11);
    
    for (uint256 k=0;k<11;k++) {
      rlist[k]=tokens[tid].hashchain[k];
    }

    hashchain = rlist;
  }
  
  // (address,token id) pairs that can perform reveals
  function is_allow_reveal(address a) public view returns (uint256[] memory) {
    uint k=0;
    for (uint256 tid=0;tid<100;tid++)
      if (allow_reveal[keccak256(abi.encodePacked(a,tid))]) k++;
    
    uint256[] memory rlist = new uint256[](k);

    k=0;
    for (uint256 tid=0;tid<100;tid++)  {
      if (allow_reveal[keccak256(abi.encodePacked(a,tid))]) {
	rlist[k]=tid;
	k++;
      }
    }
    return rlist;
  }
  
  function iToHex(bytes memory buffer) public pure returns (string memory) {
    // Fixed buffer size for hexadecimal convertion
    bytes memory converted = new bytes(buffer.length * 2);

    bytes memory _base = "0123456789abcdef";

    for (uint256 i = 0; i < buffer.length; i++) {
      converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
      converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
    }

    return string(abi.encodePacked("0x", converted));
  }

  //specify on-chain locations of encrypted SVG data for each token
  function initData(uint256[] memory tid, uint256[] memory ind, address[] memory a) public onlyInit {
    for (uint256 i = 0;i<tid.length;i++) {
      tokens[tid[i]].paths[ind[i]] = DataContract(a[i]);
    }
  }

  // claim is a commit-reveal to prevent front running
  // What you should submit is a 32-byte hash calculated by the following:
  // keccak256(token ID, address, H^11(secret), salt);
  // - token ID is between 0 and 99, indicated on back of physical hashmark
  // - address is the address you want the token minted to
  // - H^11(secret) is the 11th hash of the 32 byte secret engraved on back of physical hashmark
  // - salt is a password of your choice; will be used again during the reveal stage
  
  function commit(bytes32 a) public {
    /* safeguard: an expiring allowlist of addresses that can perform commits */
    require(allow_commit[msg.sender] || block.timestamp > deployed_ts + safeguard_expire, "Safeguard: msg.sender not on temporary allow list");
    
    commits[msg.sender].hash = a;
    commits[msg.sender].ts = block.timestamp;    //enforce 48hr between commit and reveal
  }
  
  function getCommit(address a) public view returns (bytes32 hash, uint256 ts) {
    return (commits[a].hash, commits[a].ts);    
  }
  
  function reveal(uint8 tid, bytes32 solution, string memory salt) public {
    require(tid < 100,"token ID out of range");
    require(!tokens[tid].claimed,"token ID already claimed");
    /* safeguard: an expiring allowlist of (address,token id) pairs that are elligible to be claimed (tokens get enabled for claiming once 
     I verify the physical has arrived with its owner). Safeguard expires after 180 days, at which point any
     remaining tokens are elligible for commit/reveal */
    
    require(allow_reveal[keccak256(abi.encodePacked(msg.sender,uint256(tid)))] || block.timestamp > deployed_ts + safeguard_expire, "Safeguard: (address,tokenid) pair not on temporary allow list");
    
    address i = msg.sender;
    require(commits[i].ts > 0, "No commit has been made for this address");
    require(block.timestamp - commits[i].ts > reveal_window, "need 48hr between commit and reveal");

    bytes32 b = keccak256(abi.encodePacked(bytes1(tid), msg.sender, solution, salt));
    require(b==commits[i].hash, "Commit hash doesn't match");
    require(keccak256(abi.encodePacked(solution))==tokens[tid].hashchain[0],"Invalid solution");
    
    tokens[tid].last_refresh = block.timestamp;
    tokens[tid].period = fade_period; //one year
    tokens[tid].claimed = true;
    tokens[tid].hindex++;    
    tokens[tid].hashchain[tokens[tid].hindex] = solution;

    // mint ERC721 token to msg.sender
    _mint(msg.sender, tid);
    tokens[tid].claimer = msg.sender;
    
    numTokens++;
    
    emit eClaim(tid);
  }

  // token must be "refreshed" using a series of one-time passwords.
  // keccak256 hash chain of the secret key.
  // no commit reveal scheme needed, as any front runner would only succeed in refreshing the token
  function refresh(uint256 tid, bytes32 solution) public {
    require(tid < 100, "tid out of range");
    require(tokens[tid].claimed,"Token not yet claimed");
    require(!tokens[tid].immortal,"maximum refreshes exceeded");
    
    //can only refresh after elapsed time period.
    require(block.timestamp > tokens[tid].last_refresh + tokens[tid].period, "Must wait till period expires to refresh");
    
    require(keccak256(abi.encodePacked(solution)) == tokens[tid].hashchain[tokens[tid].hindex], "Incorrect hash");
    
    tokens[tid].hindex++;
    tokens[tid].last_refresh = block.timestamp;    
    tokens[tid].hashchain[tokens[tid].hindex] = solution;
    emit eRefresh(tid,tokens[tid].hindex);    
    
    // After claim and 10 hashes, token ascends to immortality and will never fade.
    //H^1(secret) is the final refresh hash. Engraved secret  key remains unrevealed
    if (tokens[tid].hindex>=max_hashes) {
      tokens[tid].immortal = true;
      emit eAscension(tid);
    }
  }

  function fade_amount(uint256 tid) public view returns (uint256) {
    if (fadeamounts[tid] > 0) return fadeamounts[tid];
    
    //block at which token begins to fade
    uint256 c = tokens[tid].last_refresh + tokens[tid].period;
    uint256 am = 0; //amount to fade;
    
    if (tokens[tid].immortal) {
      //immortal, no fading
    } else if (block.timestamp <= c || tokens[tid].claimed==false) {
      //not at cutoff time, no fading
    } else {
      am = ((block.timestamp - c)*100) / tokens[tid].period;
      if (am > 100 ) am = 100; //clamp to 100;

      //square law
      uint256 iam = (100-am);
      am = 100 - ((iam*iam)/100);
    }
    return am;
  }
  
  function getSVG(uint256 tid) public view returns (string memory) {
    require(tid < 100, "Token ID out of range");
    //    require(tokens[tid].claimed ==true, "Token must be claimed");

    uint256 am = fade_amount(tid);
    //linear interpolation between current fill and grey
    uint256 fill = 255;
    fill = fill * (100-am) + grey_fade * am;
    fill /= 100;
    string memory hexcol = ToString.toHex(fill);
    
    string memory p1 = string(abi.encodePacked('<svg preserveAspectRatio="xMinYMin meet" version="1.1" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg"> <g stroke-width=".32"> <rect width="100%" height="100%" fill="#',hexcol,hexcol,hexcol,'" />'));
    
    string memory p2 = '</g></svg>';
    
    uint256 num_paths = 2;
    uint256[2] memory path_fills = [uint256(85*2),85];
    string memory res;
    
    for (uint pi=0;pi<num_paths;pi++) {
      //retrieve onchain encrypted data 
      bytes memory s = tokens[tid].paths[pi].data();

      string memory svg_path;

      //decrypt the data, using H(1)
      bytes32 h = tokens[tid].hashchain[1];
      if (h == 0x0) {
	svg_path = string(s); }
      else {
	svg_path = decrypt(s,h);
      }
      
      fill =  path_fills[pi];

      //linear interpolation between current fill and grey
      fill = fill * (100-am) + grey_fade * am;
      fill /= 100;
      hexcol = ToString.toHex(fill);
      
      res = string(abi.encodePacked(res,"<path d=\"",svg_path,"\" style=\"fill:#",hexcol,hexcol,hexcol,";stroke-width:0.32\" />\n"));
      
      // assemble path.
      // The fill colors will dynamically change to fade to grey based on time from last refresh.
      // if the physical with secret key is lost, the token will eventually fade.
      
      // alternatively, if max refreshes have been made, the token becomes "immortal" and immune to fading.
    }

    res = string(abi.encodePacked(p1,res,p2));
    return res;
  }

  
  // Decryption of keccak256 stream cipher
  // assumes bytelength of message is multiple of 32
  function decrypt(bytes memory s, bytes32 h) public pure returns (string memory) {
    bytes32 m;
    uint256 j = 0;
    assembly {
      j := s
    }
    
    for (uint i=0;i<s.length/32;i++) {
      h = keccak256(abi.encodePacked(h,i));      
      assembly {
        j := add(j,32)
        m := mload(j)
	mstore(j,xor(m,h))
      }
    }

    return string(s);	
  }

   function tokenURI(uint256 tokenId) public view override returns (string memory) {
     _requireMinted(tokenId);

     string memory svg = getSVG(tokenId);     

     // include metadata traits for immortal, refreshes, fade amount
     uint256 refreshes = tokens[tokenId].hindex - 1;
     uint256 fa = fade_amount(tokenId);

     string memory attributes = string(abi.encodePacked(", \"attributes\": [ {\"trait_type\": \"Refreshes\", \"value\": \"",ToString.toString(refreshes),"\"}"));
     if (tokens[tokenId].immortal) attributes = string(abi.encodePacked(attributes,", {\"trait_type\": \"Immortal\", \"value\": \"Immortal\"}"));
     if (fa > 0) attributes = string(abi.encodePacked(attributes,", {\"trait_type\": \"Fade\", \"value\": \"",ToString.toString(fa),"\"}"));
     attributes = string(abi.encodePacked(attributes,"]"));
     
     string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "HASHMARKS #', ToString.toString(tokenId), '", "description": "HASHMARKS by 0xDEAFBEEF: 100 unique hand forged iron sculptures and cryptographically linked digital tokens."', attributes, ', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

}