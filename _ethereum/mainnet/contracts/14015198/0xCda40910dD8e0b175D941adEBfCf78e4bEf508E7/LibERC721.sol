// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721Receiver.sol";
import "./Address.sol";
import "./Counters.sol";

library LibERC721 {
    using Address for address;
    using Counters for Counters.Counter;

    bytes32 constant ERC721_STORAGE_POSITION =
        keccak256("com.enterdao.landworks.erc721");

    struct ERC721Storage {
        bool initialized;
        // Token name
        string name;
        // Token symbol
        string symbol;
        // Token base URI
        string baseURI;
        // Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        // Mapping from tokenID to consumer
        mapping(uint256 => address) tokenConsumers;
        // Total minted tokens
        Counters.Counter total;
    }

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev See {IERC721Consumable-ConsumerChanged}
     */
    event ConsumerChanged(
        address indexed owner,
        address indexed consumer,
        uint256 indexed tokenId
    );

    /**
     * @dev Emiited when `baseURI` is set
     */
    event SetBaseURI(string _baseURI);

    function erc721Storage()
        internal
        pure
        returns (ERC721Storage storage erc721)
    {
        bytes32 position = ERC721_STORAGE_POSITION;
        assembly {
            erc721.slot := position
        }
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
    function safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        transfer(from, to, tokenId);
        require(
            checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) internal view returns (bool) {
        return LibERC721.erc721Storage().owners[tokenId] != address(0);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = erc721Storage().owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) internal view returns (address) {
        require(
            exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return erc721Storage().tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        return erc721Storage().operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     * Returns `tokenId`.
     *
     * Its `tokenId` will be automatically assigned (available on the emitted {IERC721-Transfer} event).
     *
     * See {xref-LibERC721-safeMint-address-uint256-}[`safeMint`]
     */
    function safeMint(address to) internal returns (uint256) {
        ERC721Storage storage erc721 = erc721Storage();
        uint256 tokenId = erc721.total.current();

        erc721.total.increment();
        safeMint(to, tokenId, "");

        return tokenId;
    }

    /**
     * @dev Same as {xref-LibERC721-safeMint-address-uint256-}[`safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        mint(to, tokenId);
        require(
            checkOnERC721Received(address(0), to, tokenId, _data),
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
    function mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        beforeTokenTransfer(address(0), to, tokenId);

        ERC721Storage storage erc721 = erc721Storage();

        erc721.balances[to] += 1;
        erc721.owners[tokenId] = to;

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
    function burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        approve(address(0), tokenId);

        ERC721Storage storage erc721 = LibERC721.erc721Storage();

        erc721.balances[owner] -= 1;
        delete erc721.owners[tokenId];

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
    function transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        ERC721Storage storage erc721 = LibERC721.erc721Storage();

        erc721.balances[from] -= 1;
        erc721.balances[to] += 1;
        erc721.owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function approve(address to, uint256 tokenId) internal {
        erc721Storage().tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Changes the consumer of `tokenId` to `consumer`.
     *
     * Emits a {ConsumerChanged} event.
     */
    function changeConsumer(
        address owner,
        address consumer,
        uint256 tokenId
    ) internal {
        ERC721Storage storage erc721 = erc721Storage();
        erc721.tokenConsumers[tokenId] = consumer;

        emit ConsumerChanged(owner, consumer, tokenId);
    }

    /**
     * @dev See {IERC721Consumable-consumerOf}.
     */
    function consumerOf(uint256 tokenId) internal view returns (address) {
        require(
            exists(tokenId),
            "ERC721Consumer: consumer query for nonexistent token"
        );

        return erc721Storage().tokenConsumers[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to consume `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function isConsumerOf(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return spender == consumerOf(tokenId);
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
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        changeConsumer(from, address(0), tokenId);
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
    function checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
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
        } else {
            return true;
        }
    }
}
