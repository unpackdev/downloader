// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.20;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or
 * {IERC721-setApprovalForAll}.
 */
abstract contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.20;

/**
 * @dev Simple implementation of `IERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
abstract contract ERC1155Holder is ERC165, IERC1155Receiver {
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
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - The `operator` cannot be the address zero.
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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TraitExchange is Ownable, ERC721Holder, ERC1155Holder {
    event OfferCreated(StructOffer);

    event Status(StructOffer, OfferStatus);

    event ExecludedFromFees(address contractAddress);
    event IncludedFromFees(address contractAddress);
    event FeesClaimedByAdmin(uint256 feesValue);
    event ExchangeFeesUpdated(uint256 prevFees, uint256 updatedFees);

    enum OfferStatus {
        pending,
        withdrawan,
        accepted,
        rejected
    }

    struct StructERC20Value {
        address erc20Contract;
        uint256 erc20Value;
    }

    struct StructERC721Value {
        address erc721Contract;
        uint256 erc721Id;
    }

    struct StructERC1155Value {
        address erc1155Contract;
        uint256 erc1155Id;
        uint256 amount;
        bytes data;
    }

    struct StructOffer {
        uint256 offerId;
        address sender;
        address receiver;
        uint256 offeredETH;
        uint256 requestedETH;
        StructERC20Value offeredERC20;
        StructERC20Value requestedERC20;
        StructERC721Value[] offeredERC721;
        StructERC721Value[] requestedERC721;
        StructERC1155Value[] offeredERC1155;
        StructERC1155Value[] requestedERC1155;
        uint256 timeStamp;
        uint256 validDuration;
        OfferStatus status;
    }

    struct StructAccount {
        uint256[] offersReceived;
        uint256[] offersCreated;
    }

    uint256 private _offerIds;
    address[] private _excludedFeesContracts;
    uint256 private _fees;
    uint256 private _feesCollected;
    uint256 private _feesClaimed;
    bool private _isTransacting;

    mapping(uint256 => StructOffer) private _mappingOffer;
    mapping(address => StructAccount) private _mappingAccounts;

    constructor(uint256 _feesInWei) {
        _fees = _feesInWei;
    }

    receive() external payable {}

    modifier noReentrancy() {
        require(
            !_isTransacting,
            "whileTreansacting(): Contract is already transaction"
        );
        _isTransacting = true;
        _;
        _isTransacting = false;
    }

    modifier isOfferValidForWithdrawal(uint256 _offerId) {
        StructOffer memory offerAccount = _mappingOffer[_offerId];

        require(
            offerAccount.sender != address(0),
            "Address zero cannot make offer."
        );

        require(
            offerAccount.receiver != address(0),
            "Cannot make offer to address zero."
        );

        require(
            offerAccount.status != OfferStatus.accepted,
            "Offer already used."
        );

        require(
            offerAccount.status != OfferStatus.withdrawan,
            "Offer already withdrawan."
        );
        _;
    }

    modifier isValidOffer(uint256 _offerId) {
        StructOffer memory offerAccount = _mappingOffer[_offerId];

        require(
            offerAccount.sender != address(0),
            "Address zero cannot make offer."
        );

        require(
            offerAccount.receiver != address(0),
            "Cannot make offer to address zero."
        );

        require(
            offerAccount.status == OfferStatus.pending,
            "Offer already accepted or withdrawan."
        );
        _;
    }

    modifier isReceiver(uint256 _offerId) {
        StructOffer memory offerAccount = _mappingOffer[_offerId];
        require(
            msg.sender == offerAccount.receiver,
            "You are not the receiver of this offer."
        );
        _;
    }

    function createOffer(StructOffer memory _structOffer)
        external
        payable
        returns (uint256 offerId)
    {
        require(
            _structOffer.receiver != address(0),
            "createOffer(): _receiver cannot be address zero."
        );
        require(
            _structOffer.offeredERC721.length < type(uint8).max,
            "createOffer(): Offered erc721 cannot be more than 255"
        );
        require(
            _structOffer.requestedERC721.length < type(uint8).max,
            "createOffer(): requested erc721 cannot be more than 255"
        );
        require(
            _structOffer.offeredERC1155.length < type(uint8).max,
            "createOffer(): Offered erc721 cannot be more than 255"
        );
        require(
            _structOffer.requestedERC1155.length < type(uint8).max,
            "createOffer(): Offered erc721 cannot be more than 255"
        );

        uint256 msgValue = msg.value;
        address msgSender = msg.sender;
        uint256 currentTime = block.timestamp;

        offerId = _offerIds;

        if (!_isBalanceExcludedFromFees(msgSender)) {
            require(
                msgValue >= _fees + _structOffer.offeredETH,
                "createOffer(): user is not included in exclude from fees and msgValue no included fees amount."
            );
            _feesCollected += _fees;
        } else {
            require(
                msgValue == _structOffer.offeredETH,
                "createOffer(): msgValue is not equal to ethOffered."
            );
        }

        StructOffer storage offerAccount = _mappingOffer[offerId];

        offerAccount.offerId = offerId;
        offerAccount.sender = msgSender;
        offerAccount.receiver = _structOffer.receiver;
        offerAccount.offeredETH = _structOffer.offeredETH;
        offerAccount.requestedETH = _structOffer.requestedETH;
        offerAccount.offeredERC20 = _structOffer.offeredERC20;
        offerAccount.requestedERC20 = _structOffer.requestedERC20;

        ///@dev please ensure that there is sufficient allowance to successfully invoke the transferFrom function.
        if (
            _structOffer.offeredERC20.erc20Contract != address(0) &&
            _structOffer.offeredERC20.erc20Value > 0
        ) {
            IERC20(_structOffer.offeredERC20.erc20Contract).transferFrom(
                msgSender,
                address(this),
                _structOffer.offeredERC20.erc20Value
            );
        }

        ///@dev please ensure that there is sufficient allowance to successfully invoke the transferFrom function.

        for (uint8 i; i < _structOffer.offeredERC721.length; ++i) {
            IERC721(_structOffer.offeredERC721[i].erc721Contract)
                .safeTransferFrom(
                    msgSender,
                    address(this),
                    _structOffer.offeredERC721[i].erc721Id
                );
            offerAccount.offeredERC721.push(_structOffer.offeredERC721[i]);
        }

        for (uint8 i; i < _structOffer.requestedERC721.length; ++i) {
            offerAccount.requestedERC721.push(_structOffer.requestedERC721[i]);
        }

        for (uint8 i; i < _structOffer.offeredERC1155.length; ++i) {
            IERC1155(_structOffer.offeredERC1155[i].erc1155Contract)
                .safeTransferFrom(
                    msgSender,
                    address(this),
                    _structOffer.offeredERC1155[i].erc1155Id,
                    _structOffer.offeredERC1155[i].amount,
                    _structOffer.offeredERC1155[i].data
                );

            offerAccount.offeredERC1155.push(_structOffer.offeredERC1155[i]);
        }

        for (uint8 i; i < _structOffer.requestedERC1155.length; ++i) {
            offerAccount.requestedERC1155.push(
                _structOffer.requestedERC1155[i]
            );
        }

        offerAccount.timeStamp = currentTime;
        offerAccount.validDuration = _structOffer.validDuration;
        offerAccount.status = OfferStatus.pending;

        _mappingAccounts[msgSender].offersCreated.push(offerId);
        _mappingAccounts[_structOffer.receiver].offersReceived.push(offerId);

        emit OfferCreated(_mappingOffer[offerId]);

        _offerIds++;
    }

    function acceptOffer(uint256 _offerId)
        external
        payable
        noReentrancy
        isValidOffer(_offerId)
        isReceiver(_offerId)
    {
        address msgSender = msg.sender;
        uint256 msgValue = msg.value;

        StructOffer storage offerAccount = _mappingOffer[_offerId];
        require(
            msgValue >= offerAccount.requestedETH,
            "Receiver has not sent enough eth, offer creator requested."
        );
        require(
            block.timestamp <
                offerAccount.timeStamp + offerAccount.validDuration,
            "Offer expired."
        );

        ///@dev please ensure that there is sufficient allowance to successfully invoke the transferFrom function.
        for (uint8 i; i < offerAccount.offeredERC721.length; i++) {
            IERC721(offerAccount.offeredERC721[i].erc721Contract).transferFrom(
                address(this),
                offerAccount.receiver,
                offerAccount.offeredERC721[i].erc721Id
            );
        }

        for (uint8 i; i < offerAccount.offeredERC1155.length; i++) {
            IERC1155(offerAccount.offeredERC1155[i].erc1155Contract)
                .safeTransferFrom(
                    address(this),
                    offerAccount.receiver,
                    offerAccount.offeredERC1155[i].erc1155Id,
                    offerAccount.offeredERC1155[i].amount,
                    offerAccount.offeredERC1155[i].data
                );
        }

        ///@dev please ensure that there is sufficient allowance to successfully invoke the transferFrom function.
        for (uint8 i; i < offerAccount.requestedERC721.length; i++) {
            IERC721(offerAccount.requestedERC721[i].erc721Contract)
                .transferFrom(
                    offerAccount.receiver,
                    offerAccount.sender,
                    offerAccount.requestedERC721[i].erc721Id
                );
        }

        for (uint8 i; i < offerAccount.requestedERC1155.length; i++) {
            IERC1155(offerAccount.requestedERC1155[i].erc1155Contract)
                .safeTransferFrom(
                    offerAccount.receiver,
                    offerAccount.sender,
                    offerAccount.requestedERC1155[i].erc1155Id,
                    offerAccount.requestedERC1155[i].amount,
                    "0x"
                );
        }

        if (offerAccount.offeredETH > 0) {
            payable(offerAccount.receiver).transfer(offerAccount.offeredETH);
        }

        if (offerAccount.requestedETH > 0) {
            payable(offerAccount.sender).transfer(offerAccount.requestedETH);
        }

        if (
            offerAccount.requestedERC20.erc20Contract != address(0) &&
            offerAccount.requestedERC20.erc20Value > 0
        ) {
            IERC20(offerAccount.requestedERC20.erc20Contract).transferFrom(
                msgSender,
                offerAccount.sender,
                offerAccount.requestedERC20.erc20Value
            );
        }

        ///@dev please ensure that there is sufficient allowance to successfully invoke the transferFrom function.
        if (
            offerAccount.offeredERC20.erc20Contract != address(0) &&
            offerAccount.offeredERC20.erc20Value > 0
        ) {
            IERC20(offerAccount.offeredERC20.erc20Contract).transfer(
                offerAccount.receiver,
                offerAccount.offeredERC20.erc20Value
            );
        }

        offerAccount.status = OfferStatus.accepted;
        emit Status(offerAccount, OfferStatus.accepted);
    }

    function rejectOffer(uint256 _offerId)
        external
        noReentrancy
        isValidOffer(_offerId)
        isReceiver(_offerId)
    {
        StructOffer storage offerAccount = _mappingOffer[_offerId];

        offerAccount.status = OfferStatus.rejected;
        emit Status(offerAccount, OfferStatus.rejected);
    }

    function withdrawOffer(uint256 _offerId)
        external
        noReentrancy
        isOfferValidForWithdrawal(_offerId)
    {
        address msgSender = msg.sender;

        StructOffer storage offerAccount = _mappingOffer[_offerId];

        require(
            msgSender == offerAccount.sender,
            "Only offer creator can withdrawOffer."
        );

        for (uint8 i; i < offerAccount.offeredERC721.length; i++) {
            IERC721(offerAccount.offeredERC721[i].erc721Contract).transferFrom(
                address(this),
                offerAccount.sender,
                offerAccount.offeredERC721[i].erc721Id
            );
        }

        for (uint8 i; i < offerAccount.offeredERC1155.length; i++) {
            IERC1155(offerAccount.offeredERC1155[i].erc1155Contract)
                .safeTransferFrom(
                    address(this),
                    offerAccount.sender,
                    offerAccount.offeredERC1155[i].erc1155Id,
                    offerAccount.offeredERC1155[i].amount,
                    offerAccount.offeredERC1155[i].data
                );
        }

        if (offerAccount.offeredETH > 0) {
            payable(offerAccount.sender).transfer(offerAccount.offeredETH);
        }

        if (
            offerAccount.offeredERC20.erc20Contract != address(0) &&
            offerAccount.offeredERC20.erc20Value > 0
        ) {
            IERC20(offerAccount.offeredERC20.erc20Contract).transfer(
                offerAccount.sender,
                offerAccount.offeredERC20.erc20Value
            );
        }

        offerAccount.status = OfferStatus.withdrawan;

        emit Status(offerAccount, OfferStatus.withdrawan);
    }

    function getOfferById(uint256 _offerId)
        public
        view
        returns (StructOffer memory)
    {
        return _mappingOffer[_offerId];
    }

    function userOffers(address _userAddress)
        external
        view
        returns (
            uint256[] memory offersCreated,
            uint256[] memory offersReceived
        )
    {
        StructAccount memory userAccount = _mappingAccounts[_userAddress];
        offersCreated = userAccount.offersCreated;
        offersReceived = userAccount.offersReceived;
    }

    function allOffersCount() external view returns (uint256 offersCount) {
        if (_offerIds > 0) {
            offersCount = _offerIds + 1;
        }
    }

    function _isBalanceExcludedFromFees(address _userAddress)
        private
        view
        returns (bool _isExcluded)
    {
        address[] memory excludedContractsList = _excludedFeesContracts;
        if (excludedContractsList.length > 0) {
            for (uint8 i; i < excludedContractsList.length; ++i) {
                if (
                    IERC721(excludedContractsList[i]).balanceOf(_userAddress) >
                    0
                ) {
                    _isExcluded = true;
                    break;
                }
            }
        }
    }

    function getFeesExcludedList() external view returns (address[] memory) {
        return _excludedFeesContracts;
    }

    function includeInFees(address _contractAddress) external onlyOwner {
        address[] memory excludedContractsList = _excludedFeesContracts;

        if (excludedContractsList.length > 0) {
            for (uint8 i; i < excludedContractsList.length; ++i) {
                if (_excludedFeesContracts[i] == _contractAddress) {
                    _excludedFeesContracts[i] ==
                        _excludedFeesContracts[
                            _excludedFeesContracts.length - 1
                        ];
                    _excludedFeesContracts.pop();

                    emit IncludedFromFees(_contractAddress);
                    break;
                }
            }
        }
    }

    function excludeFromExchangeFees(address _contractAddress)
        external
        onlyOwner
    {
        address[] memory excludedContractsList = _excludedFeesContracts;

        if (excludedContractsList.length > 0) {
            for (uint8 i; i < excludedContractsList.length; ++i) {
                if (_excludedFeesContracts[i] == _contractAddress) {
                    revert("Contract already in exempted list.");
                }
            }
        }

        _excludedFeesContracts.push(_contractAddress);
        emit ExecludedFromFees(_contractAddress);
    }

    function getFees() external view returns (uint256) {
        return _fees;
    }

    function setFees(uint256 _feesInWei) external onlyOwner {
        emit ExchangeFeesUpdated(_fees, _feesInWei);
        _fees = _feesInWei;
    }

    function getFeesCollected()
        external
        view
        returns (
            uint256 feesCollected,
            uint256 feesClaimed,
            uint256 feesPendingToClaim
        )
    {
        feesCollected = _feesCollected;
        feesClaimed = _feesClaimed;
        feesPendingToClaim = _feesCollected - _feesClaimed;
    }

    function claimFees() external noReentrancy onlyOwner {
        uint256 pendingFees = _feesCollected - _feesClaimed;
        require(pendingFees > 0, "No fees to claimed");
        _feesClaimed += pendingFees;

        payable(owner()).transfer(pendingFees);

        emit FeesClaimedByAdmin(pendingFees);
    }
}