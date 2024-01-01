/**
 *Submitted for verification at Etherscan.io on 2023-10-27
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: contracts/XANACentralLock.sol


pragma solidity ^0.8.17;

contract XANALockERC721 is IERC721Receiver {
    bytes32 internal constant XANALOCKERC721NAMESPACE = keccak256('xanalockerc721.facet');

    modifier onlyAuthorizedAddress {
        require(getXANAERC721Storage().authorizedAddresses[msg.sender], "XANALock: Not authorized");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == getXANAERC721Storage().owner, "XANALock: Not contract owner");
        _;
    }

    event NFTSLocked(address indexed owner, address indexed collection, uint256[] tokenIds, uint256 at);
    event NFTSUnlocked(address indexed owner, address indexed collection, uint256[] tokenIds, uint256 at);

    struct XANALockData {
        bool initialized;

        uint256 limit;
        address owner;

        mapping(address => bool) authorizedAddresses;

        // collection => tokenId => owner
        mapping(address => mapping(uint256 => address)) lockingData;
    }

    function getXANAERC721Storage() internal pure returns(XANALockData storage s) {
        bytes32 position = XANALOCKERC721NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function initialize() external {
        XANALockData storage s = getXANAERC721Storage();
        require(!s.initialized, "XANALock: Already initialized");
        s.limit = 5;
        s.owner = msg.sender;
        s.initialized = true;
        s.authorizedAddresses[msg.sender] = true;
    }

    function isLocked(address collection, uint256 tokenId) external view returns(bool) {
        return getXANAERC721Storage().lockingData[collection][tokenId] != address(0);
    }

    function lockNfts(address collection, uint256[] memory tokenIds) external {
        XANALockData storage s = getXANAERC721Storage();
        require(tokenIds.length <= s.limit, "XANALock: Lock limit reached");
        for (uint256 i; i < tokenIds.length; i++) {
            s.lockingData[collection][tokenIds[i]] = msg.sender;
            IERC721(collection).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
        emit NFTSLocked(msg.sender, collection, tokenIds, block.timestamp);
    }

    function unlockNfts(address collection, uint256[] memory tokenIds) external {
        XANALockData storage s = getXANAERC721Storage();
        require(tokenIds.length <= s.limit, "XANALock: Unlock limit reached");
        for (uint256 i; i < tokenIds.length; i++) {
            require(s.lockingData[collection][tokenIds[i]] == msg.sender, "XANALock: Not lock owner");
            IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            delete s.lockingData[collection][tokenIds[i]];
        }
        emit NFTSUnlocked(msg.sender, collection, tokenIds, block.timestamp);
    }

    function setLimit(uint256 _limit) external onlyOwner {
        XANALockData storage s = getXANAERC721Storage();
        s.limit = _limit;
    }

    function adminTransfer(address collection, address to, uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(collection).safeTransferFrom(address(this), to, tokenIds[i]);
        }
    }

    function adminSetLockStatus(address user, address collection, uint256[] memory tokenIds, bool[] memory statuses) external onlyAuthorizedAddress {
        require(tokenIds.length == statuses.length, "mismatch");
        XANALockData storage s = getXANAERC721Storage();
        for (uint256 i; i < tokenIds.length; i++) {
            if (statuses[i]) {
                s.lockingData[collection][tokenIds[i]] = user;
            } else {
                delete s.lockingData[collection][tokenIds[i]];
            }
        }
    }

    function transferOwnership(address _add) external onlyOwner {
        XANALockData storage s = getXANAERC721Storage();
        s.owner = _add;
    }

    function allowAddress(address _add, bool status) external onlyOwner {
        XANALockData storage s = getXANAERC721Storage();
        s.authorizedAddresses[_add] = status;
    }

    function adminBulkSetLockStatus(address collection, address[] memory users, uint256[] memory tokenIds, bool[] memory statuses) external onlyAuthorizedAddress {
        require(tokenIds.length == users.length && tokenIds.length == statuses.length, "mismatch");
        XANALockData storage s = getXANAERC721Storage();
        for (uint256 i; i < users.length; i++) {
            if (statuses[i]) {
                s.lockingData[collection][tokenIds[i]] = users[i];
            } else {
                delete s.lockingData[collection][tokenIds[i]];
            }
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}