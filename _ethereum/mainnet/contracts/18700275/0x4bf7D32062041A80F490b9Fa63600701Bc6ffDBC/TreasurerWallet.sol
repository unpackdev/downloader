// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155.sol)

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

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
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: contracts/Controllable.sol

/**
 * @title Controllable
 * @dev Contract used for handling controllers.
 */
contract Controllable is Ownable {
    address public controller;

    /**
     * @dev The `account` is not authorized.
     */
    error ControllableUnauthorizedAccount(address account);

    /**
     * @dev The controller address is the same as current one.
     */
    error ControllableTheSameValue();

    /**
     * @dev The `controller` is invalid (zero address or not a contract).
     */
    error ControllableInvalidController(address controller);

    /**
     * @dev Emitted when the `controller` is set to a new address.
     */
    event ControllerChanged(address indexed controller);

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        if (msg.sender != controller) {
            revert ControllableUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Throws if called by any account other than the controller or the owner.
     */
    modifier onlyControllerOrOwner() {
        if (msg.sender != controller && msg.sender != owner()) {
            revert ControllableUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Initializes the contract.
     */
    constructor() Ownable(_msgSender()) {}

    /**
     * @dev Sets address of the controller to `newController`.
     */
    function setController(address newController) external onlyOwner {
        if (newController == controller) {
            revert ControllableTheSameValue();
        }

        if (newController == address(0) || newController.code.length == 0) {
            revert ControllableInvalidController(newController);
        }

        controller = newController;

        emit ControllerChanged(controller);
    }
}

// File: contracts/TreasurerWallet.sol

/**
 * @title TreasurerWallet
 * @dev Contract that keeps tokens.
 */
contract TreasurerWallet is Controllable, ERC165, IERC721Receiver, IERC1155Receiver {
    bool public isLocked = false;

    /**
     * @dev The beneficiary cannot be the zero address.
     */
    error TreasurerWalletInvalidBeneficiary();

    /**
     * @dev The amount cannot be zero.
     */
    error TreasurerWalletInvalidAmont();

    /**
     * @dev The controller was not set.
     */
    error TreasurerWalletInvalidController();

    /**
     * @dev The `wallet` is invalid (zero address or not a contract).
     */
    error TreasurerWalletInvalidWallet(address wallet);

    /**
     * @dev List cannot be empty.
     */
    error TreasurerWalletEmptyList();

    /**
     * @dev Lists must have the same length.
     */
    error TreasurerWalletListsLengthMismatch();

    /**
     * @dev Tokens migration was already started.
     */
    error TreasurerWalletMigrationAlreadyStarted();

    /**
     * @dev Tokens migration was not started yet.
     */
    error TreasurerWalletMigrationNotStartedYet();

    /**
     * @dev Emitted when the token migration starts and normal operations are stopped.
     */
    event MigrationStarted();

    /**
     * @dev Emitted when an ERC721 token identified by the `token` and `identifier` is received by the contract.
     */
    event ERC721Received(address indexed token, uint256 indexed identifier);

    /**
     * @dev Emitted when an ERC1155 token identified by the `token` and `identifier` is received by the contract.
     */
    event ERC1155Received(address indexed token, uint256 indexed identifier, uint256 indexed amount);

    /**
     * @dev Emitted when an ERC1155 token batch identified by the `token` and `identifiers` is received by the contract.
     */
    event ERC1155BatchReceived(address indexed token, uint256[] indexed identifiers, uint256[] indexed amounts);

    /**
     * @dev Emitted when an ERC721 token identified by the `token` and `identifier` is withdrawn for the `beneficiary`.
     */
    event ERC721Withdrawal(address indexed token, uint256 indexed identifier, address indexed beneficiary);

    /**
     * @dev Emitted when an ERC1155 token identified by the `token` and `identifier` is withdrawn for the `beneficiary`.
     */
    event ERC1155Withdrawal(address indexed token, uint256 indexed identifier, uint256 indexed amount, address beneficiary);

    /**
     * @dev Emitted when an ERC1155 token batch identified by the `token` and `identifiers` is withdrawn for the `beneficiary`.
     */
    event ERC1155BatchWithdrawal(address indexed token, uint256[] indexed identifiers, uint256[] indexed amounts, address beneficiary);

    /**
     * @dev Throws if called after the contract was locked.
     */
    modifier onlyUnlocked() {
        if (controller == address(0)) {
            revert TreasurerWalletInvalidController();
        }

        if (isLocked) {
            revert TreasurerWalletMigrationAlreadyStarted();
        }
        _;
    }

    /**
     * @dev Starts tokens migration.
     */
    function startMigration() external onlyUnlocked onlyOwner {
        isLocked = true;

        emit MigrationStarted();
    }

    /**
     * @dev Allows to migrate ERC721 tokens to new wallet address by the owner.
     */
    function migrateERC721(address[] calldata tokens, uint256[] calldata identifiers, address wallet) external onlyOwner {
        if (!isLocked) {
            revert TreasurerWalletMigrationNotStartedYet();
        }

        if (wallet == address(0) || wallet.code.length == 0) {
            revert TreasurerWalletInvalidWallet(wallet);
        }

        if (tokens.length != identifiers.length) {
            revert TreasurerWalletListsLengthMismatch();
        }

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC721(tokens[i]).safeTransferFrom(address(this), wallet, identifiers[i], "");
        }
    }

    /**
     * @dev Allows to migrate ERC1155 tokens to new wallet address by the owner.
     */
    function migrateERC1155(address[] calldata tokens, uint256[] calldata identifiers, uint256[] calldata amounts, address wallet) external onlyOwner {
        if (!isLocked) {
            revert TreasurerWalletMigrationNotStartedYet();
        }

        if (wallet == address(0) || wallet.code.length == 0) {
            revert TreasurerWalletInvalidWallet(wallet);
        }

        if (tokens.length != identifiers.length || tokens.length != amounts.length) {
            revert TreasurerWalletListsLengthMismatch();
        }

        for (uint256 i = 0; i < tokens.length; ++i) {
            if (amounts[i] == 0) {
                revert TreasurerWalletInvalidAmont();
            }

            IERC1155(tokens[i]).safeTransferFrom(address(this), wallet, identifiers[i], amounts[i], "");
        }
    }

    /**
     * @dev Allows to withdraw ERC721 token by the controller.
     */
    function withdrawERC721(address token, uint256 identifier, address beneficiary) external onlyUnlocked onlyController {
        if (beneficiary == address(0)) {
            revert TreasurerWalletInvalidBeneficiary();
        }

        IERC721(token).safeTransferFrom(address(this), beneficiary, identifier, "");

        emit ERC721Withdrawal(token, identifier, beneficiary);
    }

    /**
     * @dev Allows to withdraw ERC1155 token by the controller.
     */
    function withdrawERC1155(address token, uint256 identifier, uint256 amount, address beneficiary) external onlyUnlocked onlyController {
        if (beneficiary == address(0)) {
            revert TreasurerWalletInvalidBeneficiary();
        }

        if (amount == 0) {
            revert TreasurerWalletInvalidAmont();
        }

        IERC1155(token).safeTransferFrom(address(this), beneficiary, identifier, amount, "");

        emit ERC1155Withdrawal(token, identifier, amount, beneficiary);
    }

    /**
     * @dev Allows to withdraw multiple ERC1155 tokens by the controller.
     */
    function withdrawERC1155Batch(address token, uint256[] calldata identifiers, uint256[] calldata amounts, address beneficiary) external onlyUnlocked onlyController {
        if (beneficiary == address(0)) {
            revert TreasurerWalletInvalidBeneficiary();
        }

        if (identifiers.length == 0 || amounts.length == 0) {
            revert TreasurerWalletEmptyList();
        }

        if (identifiers.length != amounts.length) {
            revert TreasurerWalletListsLengthMismatch();
        }

        IERC1155(token).safeBatchTransferFrom(address(this), beneficiary, identifiers, amounts, "");

        emit ERC1155BatchWithdrawal(token, identifiers, amounts, beneficiary);
    }

    /**
     * @dev Emits event when ERC721 tokens are received.
     */
    function onERC721Received(address, address, uint256 identifier, bytes calldata) external override returns (bytes4) {
        if (isLocked) {
            return "";
        }

        emit ERC721Received(_msgSender(), identifier);

        return this.onERC721Received.selector;
    }

    /**
     * @dev Emits event when ERC1155 tokens are received.
     */
    function onERC1155Received(address, address, uint256 identifier, uint256 amount, bytes calldata) external override returns (bytes4) {
        if (isLocked) {
            return "";
        }

        emit ERC1155Received(_msgSender(), identifier, amount);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Emits event when ERC1155 tokens are received.
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata identifiers, uint256[] calldata amounts, bytes calldata) external override returns (bytes4) {
        if (isLocked) {
            return "";
        }

        emit ERC1155BatchReceived(_msgSender(), identifiers, amounts);

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Returns true if `interfaceId` is supported.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}