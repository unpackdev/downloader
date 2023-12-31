// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./BytesLib.sol";
import "./Address.sol";

/**
 * @title ERC-721 Non-Fungible Token optimized for batch minting
 * @notice a bytes2 (uint16) is used to store the token id so the collection should be lower than 2^16 = 65536 items
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 *      Based on the study for writing indexes and addresses, we use a single mapping for storing all the data
 *      We use the uint16 / bytes2 tokenId
 */
abstract contract ERC721 is IERC721, IERC721Metadata, Context, ERC165 {
    using Address for address;

    // Mapping from address to tokenIds. This is the single source of truth for the data
    mapping(address => bytes) internal _tokensByOwner;

    // Because mapping in solidity are not real hash tables, one needs to keep track of the keys.
    // One address is 20 bytes
    bytes internal owners;

    // Number of tokens
    uint16 public constant MAX_NUMBER_OF_TOKENS = 10_000;

    // Bool array to store if the token is minted. To save on gas for token lookup in _tokensByOwner.
    bool[MAX_NUMBER_OF_TOKENS] internal tokenExists;

    // Mapping from token ID to approved address
    mapping(uint16 => address) internal _tokenApprovals;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev There are two bytes per tokenId
     * @param owner address The address we retrieve the balance for
     * @return uint256 The number of tokens owned by the address
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return _tokensByOwner[owner].length / 2;
    }

    function _balanceOf(uint256 ownerIndex) internal view returns (uint256) {
        require(ownerIndex < owners.length, "ERC721: ownerIndex out of bound");
        return balanceOf(BytesLib.toAddress(owners, ownerIndex));
    }

    /// @dev Returns the index of owner in the internal array of owners. Revert if not found.
    /// @param owner address The address we retrieve the index for
    function getOwnerIndex(address owner) public view returns (uint256) {
        uint256 index = 0;
        while (index < owners.length) {
            if (BytesLib.toAddress(owners, index) == owner) {
                return index / 20;
            }
            index += 20;
        }
        revert("ERC721: Owner not found");
    }

    /// @dev Returns the array of bool telling if a token exists or not.
    function getTokenExists()
        external
        view
        returns (bool[MAX_NUMBER_OF_TOKENS] memory)
    {
        return tokenExists;
    }

    /**
     * @param tokenId uint16 A given token id
     * @return bool True if the token exists, false otherwise
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenExists[tokenId];
    }

    /**
     * @dev This is copied from OpenZeppelin's implementation
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
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    /// @dev This is the core unsafe implementation of a transfer.
    /// @param from address The address which you want to transfer the token from
    /// @param fromIndex uint256 The index of "from" in the owners bytes. This is to avoid a search in the array.
    /// @param to address The address which you want to transfer the token to
    /// @param tokenIndex uint256 The index of the token to transfer in the from's token list.
    function _transfer(
        address from,
        uint256 fromIndex,
        address to,
        uint256 tokenIndex
    ) private {
        require(
            BytesLib.toAddress(owners, fromIndex * 20) == from,
            "ERC721: transfer from address is invalid"
        );
        if (_tokensByOwner[to].length == 0) {
            owners = bytes.concat(owners, bytes20(to));
        }
        bytes memory tokenId = BytesLib.slice(
            _tokensByOwner[from],
            tokenIndex,
            tokenIndex + 2
        );
        if (_tokensByOwner[from].length == 2) {
            owners = bytes.concat(
                BytesLib.slice(owners, 0, fromIndex * 20),
                BytesLib.slice(
                    owners,
                    (fromIndex + 1) * 20,
                    owners.length - (fromIndex + 1) * 20
                )
            );
            delete _tokensByOwner[from];
        } else {
            _tokensByOwner[from] = bytes.concat(
                BytesLib.slice(_tokensByOwner[from], 0, tokenIndex),
                BytesLib.slice(
                    _tokensByOwner[from],
                    tokenIndex + 2,
                    _tokensByOwner[from].length - tokenIndex - 2
                )
            );
        }
        _tokensByOwner[to] = bytes.concat(_tokensByOwner[to], tokenId);
        emit Transfer(from, to, BytesLib.toUint16(tokenId, 0));
    }

    /// @dev Transfer token with minimal computing since all the required data to check is given
    /// @param from address The address which you want to transfer the token from
    /// @param fromIndex uint256 The index of "from" in the owners bytes. This is to avoid a search in the array.
    /// @param to address The address which you want to transfer the token to
    /// @param tokenIndex uint256 The index of the token to transfer in the from's token list.
    function safeTransferFrom(
        address from,
        uint256 fromIndex,
        address to,
        uint256 tokenIndex
    ) external {
        require(from != address(0), "ERC721: from cannot be the zero address");
        require(to != address(0), "ERC721: to cannot be the zero address");
        require(
            tokenIndex < _tokensByOwner[from].length / 2,
            "ERC721: token index out of range"
        );
        uint16 tokenId = BytesLib.toUint16(
            _tokensByOwner[from],
            tokenIndex * 2
        );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, fromIndex, to, tokenIndex);
        _checkOnERC721Received(from, to, tokenId, "");
    }

    /**
     * @dev This is the core unsafe implementation of a mint.
     * @param to address The receiver of the tokens
     * @param tokenIds bytes The token ids to mint
     */
    function _mintBatch(address to, bytes calldata tokenIds) private {
        require(tokenIds.length > 0, "ERC721: cannot mint with no token Ids");
        require(
            tokenIds.length % 2 == 0,
            "ERC721: tokenIds should be bytes of uint16"
        );
        if (_tokensByOwner[to].length == 0) {
            owners = bytes.concat(owners, bytes20(to));
        }
        for (uint256 i = 0; i < tokenIds.length; i += 2) {
            require(
                !tokenExists[BytesLib.toUint16(tokenIds, i)],
                "ERC721: token already exists"
            );
            tokenExists[BytesLib.toUint16(tokenIds, i)] = true;
            emit Transfer(address(0), to, BytesLib.toUint16(tokenIds, i));
        }
        _tokensByOwner[to] = bytes.concat(_tokensByOwner[to], tokenIds);
    }

    /// @dev Add a batch of token Ids given as a bytes array to the sender
    /// @param to address minting token to this address
    /// @param tokenIds bytes a bytes of tokenIds as bytes2 (uint16)
    function safeMintBatch(address to, bytes calldata tokenIds)
        internal
        virtual
    {
        _mintBatch(to, tokenIds);
        _checkOnERC721Received(
            address(0),
            to,
            BytesLib.toUint16(tokenIds, 0),
            ""
        );
    }

    /// @dev Approve "to" to manage token Id
    /// @param to address The address which will manage the token Id
    /// @param tokenId uint256 The token Id to manage
    /// @param tokenIndex uint256 The index of the token in the owner's list
    function approve(
        address to,
        uint256 tokenId,
        uint256 tokenIndex
    ) external {
        if (_tokenApprovals[uint16(tokenId)] != _msgSender()) {
            // if sender is not approved, they need to be the owner
            require(
                tokenIndex * 2 < _tokensByOwner[_msgSender()].length,
                "ERC721: token index out of range"
            );
            require(
                BytesLib.toUint16(
                    _tokensByOwner[_msgSender()],
                    tokenIndex * 2
                ) == tokenId,
                "ERC721: caller is neither approved nor owner"
            );
            emit Approval(_msgSender(), to, tokenId);
        }
        _tokenApprovals[uint16(tokenId)] = to;
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(_exists(tokenId), "ERC721: token does not exist");
        return _tokenApprovals[uint16(tokenId)];
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     * @param operator The address of the operator to add or remove.
     * @param _approved Whether to add or remove `operator` as an operator.
     */
    function setApprovalForAll(address operator, bool _approved)
        external
        override
    {
        require(
            operator != _msgSender(),
            "ERC721: cannot approve caller as operator"
        );
        bytes memory tokens = _tokensByOwner[_msgSender()];
        for (uint256 i = 0; i < tokens.length; i += 2) {
            _tokenApprovals[BytesLib.toUint16(tokens, i)] = _approved
                ? operator
                : address(0);
        }

        emit ApprovalForAll(_msgSender(), operator, _approved);
    }

    /**
     * @dev Returns whether `operator` is an approved operator for the caller.
     * @param owner The address of the owner to check.
     * @param operator The address of the operator to check.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        bytes memory tokens = _tokensByOwner[owner];
        for (uint256 i = 0; i < tokens.length; i += 2) {
            if (_tokenApprovals[BytesLib.toUint16(tokens, i)] != operator) {
                return false;
            }
        }
        return true;
    }

    /// @dev Copied from OpenZeppelin ERC721.sol
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Functions that should not be used but here for compatibility with ERC721
    // These are gassy.
    ///////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        require(from != address(0), "ERC721: from cannot be the zero address");
        require(to != address(0), "ERC721: to cannot be the zero address");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        uint256 tokenIndex = 0;
        while (
            BytesLib.toUint16(_tokensByOwner[from], tokenIndex) != tokenId &&
            tokenIndex < _tokensByOwner[from].length
        ) {
            tokenIndex += 2;
        }
        require(
            tokenIndex < _tokensByOwner[from].length,
            "ERC721: from does not own the token"
        );

        uint256 fromIndex;
        for (fromIndex = 0; fromIndex < owners.length; fromIndex += 20) {
            if (BytesLib.toAddress(owners, fromIndex) == from) {
                break;
            }
        }
        require(
            BytesLib.toAddress(owners, fromIndex) == from,
            "ERC721: from is not in owners list"
        );
        _transfer(from, fromIndex, to, tokenIndex);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external override {
        _safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    ) external override {
        require(from != address(0), "ERC721: from cannot be the zero address");
        require(to != address(0), "ERC721: to cannot be the zero address");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        uint256 tokenIndex = 0;
        while (
            BytesLib.toUint16(_tokensByOwner[from], tokenIndex) != tokenId &&
            tokenIndex < _tokensByOwner[from].length
        ) {
            tokenIndex += 2;
        }
        require(
            tokenIndex < _tokensByOwner[from].length,
            "ERC721: from does not own the token"
        );

        uint256 fromIndex;
        for (fromIndex = 0; fromIndex < owners.length; fromIndex += 20) {
            if (BytesLib.toAddress(owners, fromIndex) == from) {
                break;
            }
        }
        require(
            BytesLib.toAddress(owners, fromIndex) == from,
            "ERC721: from is not in owners list"
        );
        _transfer(from, fromIndex, to, tokenIndex);
    }

    /**
     * @dev For each owner, we go through all their tokens and check if the sought token is in the list. This lookup
     *      is gassy but we do not expect to pay them often as we provide other mean of doing the transfers.
     * @param tokenId uint16 A given token id
     * @return address The owner of the token, might be 0x0 if not found
     */
    function _ownerOf(uint256 tokenId) private view returns (address) {
        address owner = address(0);
        for (uint256 i = 0; i < owners.length; i += 20) {
            address currentOwner = BytesLib.toAddress(owners, i);
            for (
                uint256 j = 0;
                j < _tokensByOwner[currentOwner].length;
                j += 2
            ) {
                if (
                    BytesLib.toUint16(_tokensByOwner[currentOwner], j) ==
                    tokenId
                ) {
                    owner = currentOwner;
                    break;
                }
            }
            if (owner != address(0)) {
                break;
            }
        }
        return owner;
    }

    /**
     * @dev This is the public ownerOf, see IERC721. We fail fast with the initial check. There is no good
     *      reason to call this function on chain.
     * @param tokenId uint265 A given token id
     * @return address The owner of the token.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _ownerOf(tokenId);
    }

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
    function approve(address to, uint256 tokenId) external override {
        address owner = _ownerOf(tokenId);
        require(
            owner != address(0),
            "ERC721: approve query for nonexistent token"
        );
        require(
            _tokenApprovals[uint16(tokenId)] == _msgSender() ||
                owner == _msgSender(),
            "ERC721: caller is not the owner nor an approved operator for the token"
        );
        _tokenApprovals[uint16(tokenId)] = to;
        emit Approval(owner, to, tokenId);
    }
}
