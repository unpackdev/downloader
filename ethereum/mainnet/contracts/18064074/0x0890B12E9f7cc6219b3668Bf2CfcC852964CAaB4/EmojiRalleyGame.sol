// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
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
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
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
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/NewEmojiGame.sol


pragma solidity ^0.8.0;







contract EmojiRalleyGame is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // State variables
    mapping(address => uint256) public ethBalances;
    mapping(address => mapping(address => uint256)) public tokenBalances; // ERC20 token balances
    mapping(address => bool) public allowedTokens; // Allowed ERC20 tokens for deposit
    address[] public allowedTokenAddresses; // List of allowed ERC20 token addresses

    mapping(address => bool) public allowedERC721s; // Allowed ERC721 tokens for free game rewards
    mapping(address => bool) public allowedERC1155s; // Allowed ERC1155 tokens for free game rewards

    struct Player {
        bool exists;
        uint256 totalWon;
        uint256 gamesPlayed;
        uint256 gamesWon;
        uint256 totalWageredEth; // Total ETH wagered by the player
        uint256 totalWageredErc20; // Total ERC20 wagered by the player
        mapping(address => uint256) erc20Winnings; // ERC20 token address to amount won
        uint256 totalEthRewards;  // Total ETH rewards earned by the player
        mapping(address => uint256) erc20Rewards; // ERC20 token address to rewards earned
        mapping(address => uint256) totalErc20Rewards; // Total ERC20 rewards earned by the player for each token
    }

    mapping(address => Player) public leaderboard;

    struct RewardsInfo {
        bool rewardsEnabled;
        uint256 thresholdEth;
        uint256 thresholdErc20;
        uint256 rewardPercentage; // Represented in basis points, so 100 = 1%
        uint256 epoch; // Epoch for controlling reward periods
    }

    RewardsInfo public rewardsInfo;
    mapping(address => uint256) public ethWageredSinceLastReward; // Tracks ETH wagered since last reward for each player
    mapping(address => mapping(address => uint256)) public erc20WageredSinceLastReward; // Tracks ERC20 wagered since last reward for each player

    // Events
    event Deposited(address indexed user, uint256 amount);
    event TokenDeposited(address indexed user, address token, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event TokenWithdrawn(address indexed user, address token, uint256 amount);
    event TokenAdded(address token);
    event WinnerPaid(address indexed winner, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    address public HOUSE_ADDRESS;

    constructor() {
        // Initialize rewards parameters
        rewardsInfo = RewardsInfo({
            rewardsEnabled: false,
            thresholdEth: 0.5 ether,
            thresholdErc20: 10000,
            rewardPercentage: 100, // 1%
            epoch: 0
        });
    }

    function deposit() external payable {
        ethBalances[msg.sender] = ethBalances[msg.sender].add(msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    function depositToken(address token, uint256 amount) external {
        require(allowedTokens[token], "Token not allowed");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].add(amount);
        emit TokenDeposited(msg.sender, token, amount);
    }

    function depositERC721(address token, uint256 tokenId) external {
        require(allowedERC721s[token], "ERC721 token not allowed");
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
    }

    function depositERC1155(address token, uint256 tokenId, uint256 amount, bytes calldata data) external {
        require(allowedERC1155s[token], "ERC1155 token not allowed");
        IERC1155(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, data);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(ethBalances[msg.sender] >= amount, "Insufficient balance");
        ethBalances[msg.sender] = ethBalances[msg.sender].sub(amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawToken(address token, uint256 amount) external nonReentrant {
        require(tokenBalances[msg.sender][token] >= amount, "Insufficient balance");
        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(amount);
        IERC20(token).transfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, token, amount);
    }

    function addAllowedToken(address token) external onlyOwner {
        if (!allowedTokens[token]) {
            allowedTokens[token] = true;
            allowedTokenAddresses.push(token);
            emit TokenAdded(token);
        }
    }

    function addAllowedERC721(address token) external onlyOwner {
        allowedERC721s[token] = true;
    }

    function addAllowedERC1155(address token) external onlyOwner {
        allowedERC1155s[token] = true;
    }

    function setHouseAddress(address _newHouseAddress) external onlyOwner {
        HOUSE_ADDRESS = _newHouseAddress;
    }

    function deductPlayerWagersAndHouseShare(address[] memory players, uint256[] memory wagers) external onlyOwner {
        require(players.length == wagers.length, "Players and wagers length mismatch");

        uint256 totalWagered = 0;
        for (uint256 i = 0; i < players.length; i++) {
            require(ethBalances[players[i]] >= wagers[i], "Insufficient balance for wager");
            ethBalances[players[i]] = ethBalances[players[i]].sub(wagers[i]);
            totalWagered = totalWagered.add(wagers[i]);

            // Update individual player's wagered amount for reward calculations
            ethWageredSinceLastReward[players[i]] = ethWageredSinceLastReward[players[i]].add(wagers[i]);
        }

        uint256 houseShare = totalWagered.mul(10).div(100);
        ethBalances[HOUSE_ADDRESS] = ethBalances[HOUSE_ADDRESS].add(houseShare);
    }

    function refundPlayers(address token, address[] memory players, uint256[] memory wagers) external onlyOwner {
        require(players.length == wagers.length, "Players and wagers length mismatch");

        uint256 totalWagered = 0;

        for (uint256 i = 0; i < players.length; i++) {
            if (token == address(0)) {
                // Handle ETH refunds
                ethBalances[players[i]] = ethBalances[players[i]].add(wagers[i]);
                ethWageredSinceLastReward[players[i]] = ethWageredSinceLastReward[players[i]].sub(wagers[i]);
            } else {
                // Handle ERC20 refunds
                require(allowedTokens[token], "Token not allowed");
                tokenBalances[players[i]][token] = tokenBalances[players[i]][token].add(wagers[i]);
                erc20WageredSinceLastReward[players[i]][token] = erc20WageredSinceLastReward[players[i]][token].sub(wagers[i]);
            }

            totalWagered = totalWagered.add(wagers[i]);
        }

        uint256 houseShare = totalWagered.mul(10).div(100);

        if (token == address(0)) {
            ethBalances[HOUSE_ADDRESS] = ethBalances[HOUSE_ADDRESS].sub(houseShare);
        } else {
            tokenBalances[HOUSE_ADDRESS][token] = tokenBalances[HOUSE_ADDRESS][token].sub(houseShare);
        }
    }


    function deductPlayerWagersAndHouseShareERC20(address token, address[] memory players, uint256[] memory wagers) external onlyOwner {
        require(allowedTokens[token], "Token not allowed");
        require(players.length == wagers.length, "Players and wagers length mismatch");

        uint256 totalWagered = 0;
        for (uint256 i = 0; i < players.length; i++) {
            require(tokenBalances[players[i]][token] >= wagers[i], "Insufficient balance for wager");
            tokenBalances[players[i]][token] = tokenBalances[players[i]][token].sub(wagers[i]);
            totalWagered = totalWagered.add(wagers[i]);

            // Update individual player's wagered amount for reward calculations
            erc20WageredSinceLastReward[players[i]][token] = erc20WageredSinceLastReward[players[i]][token].add(wagers[i]);
        }

        uint256 houseShare = totalWagered.mul(10).div(100);
        tokenBalances[HOUSE_ADDRESS][token] = tokenBalances[HOUSE_ADDRESS][token].add(houseShare);
    }

    function handleFreeGameResults(address winner, uint256 winningsAmount) external onlyOwner {
        // Credit ETH winnings to the winner's balance from the house
        ethBalances[HOUSE_ADDRESS] = ethBalances[HOUSE_ADDRESS].sub(winningsAmount);
        ethBalances[winner] = ethBalances[winner].add(winningsAmount);
        emit WinnerPaid(winner, winningsAmount);
    }

    function handleFreeGameResultsERC20(address token, address winner, uint256 winningsAmount) external onlyOwner {
        require(allowedTokens[token], "Token not allowed");

        // Credit ERC20 winnings to the winner's balance from the house
        tokenBalances[HOUSE_ADDRESS][token] = tokenBalances[HOUSE_ADDRESS][token].sub(winningsAmount);
        tokenBalances[winner][token] = tokenBalances[winner][token].add(winningsAmount);
        emit WinnerPaid(winner, winningsAmount);
    }

    function handleFreeGameResultsERC721(address token, address winner, uint256 tokenId) external onlyOwner {
        require(allowedERC721s[token], "ERC721 token not allowed");
        IERC721(token).transferFrom(address(this), winner, tokenId);
    }

    function handleFreeGameResultsERC1155(address token, address winner, uint256 tokenId, uint256 amount, bytes calldata data) external onlyOwner {
        require(allowedERC1155s[token], "ERC1155 token not allowed");
        IERC1155(token).safeTransferFrom(address(this), winner, tokenId, amount, data);
    }

    function handleGameResults(address winner, uint256 winningsAmount, address[] memory players, uint256[] memory wagers) external onlyOwner {
        require(players.length == wagers.length, "Players and wagers length mismatch");

        // Credit ETH winnings to the winner's balance inside the contract
        ethBalances[winner] = ethBalances[winner].add(winningsAmount);
        updateLeaderboard(winner, winningsAmount, false, address(0)); // Update the leaderboard for ETH game
        emit WinnerPaid(winner, winningsAmount);
    }

    function handleGameResultsERC20(address token, address winner, uint256 winningsAmount, address[] memory players, uint256[] memory wagers) external onlyOwner {
        require(allowedTokens[token], "Token not allowed");
        require(players.length == wagers.length, "Players and wagers length mismatch");

        // Credit ERC20 winnings to the winner's balance inside the contract
        tokenBalances[winner][token] = tokenBalances[winner][token].add(winningsAmount);

        uint256 winnerWager = 0;

        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == winner) {
                winnerWager = wagers[i];
                break;
            }
        }

        updateLeaderboard(winner, winningsAmount.add(winnerWager), true, token); // Update the leaderboard for ERC20 game including wagered amount
        emit WinnerPaid(winner, winningsAmount);
    }

    function handleGameResultsERC721(address winner, address[] memory players, address[] memory tokenAddresses, uint256[] memory tokenIds) external onlyOwner {
        require(players.length == tokenAddresses.length && players.length == tokenIds.length, "Arrays length mismatch");

        for (uint256 i = 0; i < players.length; i++) {
            require(IERC721(tokenAddresses[i]).ownerOf(tokenIds[i]) == address(this), "The contract does not own this token");
            require(allowedERC721s[tokenAddresses[i]], "Token not allowed");
            IERC721(tokenAddresses[i]).transferFrom(address(this), winner, tokenIds[i]);
        }
    }

    function handleGameResultsERC1155(address winner, address[] memory players, address[] memory tokenAddresses, uint256[] memory tokenIds, uint256[] memory amounts) external onlyOwner {
        require(players.length == tokenAddresses.length && players.length == tokenIds.length && players.length == amounts.length, "Arrays length mismatch");

        for (uint256 i = 0; i < players.length; i++) {
            require(allowedERC1155s[tokenAddresses[i]], "Token not allowed");
            require(IERC1155(tokenAddresses[i]).balanceOf(address(this), tokenIds[i]) >= amounts[i], "Not enough tokens to transfer");
            IERC1155(tokenAddresses[i]).safeTransferFrom(address(this), winner, tokenIds[i], amounts[i], "");
        }
    }

    function updateLeaderboard(address _player, uint256 _amount, bool isERC20, address token) internal {
        uint256 netWinnings = _amount.mul(90).div(100);

        if (leaderboard[_player].exists) {
            leaderboard[_player].totalWon = leaderboard[_player].totalWon.add(netWinnings);
            leaderboard[_player].gamesWon = leaderboard[_player].gamesWon.add(1);
            if (isERC20) {
                leaderboard[_player].erc20Winnings[token] = leaderboard[_player].erc20Winnings[token].add(netWinnings);
                leaderboard[_player].totalWageredErc20 = leaderboard[_player].totalWageredErc20.add(_amount); // Add the full wagered amount
            } else {
                leaderboard[_player].totalWageredEth = leaderboard[_player].totalWageredEth.add(_amount);
            }
        } else {
            leaderboard[_player].exists = true;
            leaderboard[_player].totalWon = netWinnings;
            leaderboard[_player].gamesPlayed = 1;
            leaderboard[_player].gamesWon = 1;
            if (isERC20) {
                leaderboard[_player].erc20Winnings[token] = netWinnings;
                leaderboard[_player].totalWageredErc20 = _amount; // Set the full wagered amount
            } else {
                leaderboard[_player].totalWageredEth = _amount;
            }
        }
    }


    function updateRewardParameters(bool _rewardsEnabled, uint256 _thresholdEth, uint256 _thresholdErc20, uint256 _rewardPercentage) external onlyOwner {
        bool changedRewardsStatus = (_rewardsEnabled != rewardsInfo.rewardsEnabled);
        rewardsInfo.rewardsEnabled = _rewardsEnabled;
        rewardsInfo.thresholdEth = _thresholdEth;
        rewardsInfo.thresholdErc20 = _thresholdErc20;
        rewardsInfo.rewardPercentage = _rewardPercentage;
        
        // Only increment the epoch if the rewards status is toggled
        if (changedRewardsStatus) {
            rewardsInfo.epoch = rewardsInfo.epoch.add(1);
        }
    }

    function hasRewardsAvailable(address user) external view returns (bool) {
        if (ethWageredSinceLastReward[user] >= rewardsInfo.thresholdEth) {
            return true;
        }

        for (uint256 i = 0; i < allowedTokenAddresses.length; i++) {
            address tokenAddress = allowedTokenAddresses[i];
            if (erc20WageredSinceLastReward[user][tokenAddress] >= rewardsInfo.thresholdErc20) {
                return true;
            }
        }

        return false;
    }

    function claimRewardForPlayers(address[] memory _players) external onlyOwner {
        require(rewardsInfo.rewardsEnabled, "Rewards are not enabled");

        for (uint256 j = 0; j < _players.length; j++) {
            address currentPlayer = _players[j];
            uint256 rewardAmountEth = 0;
            uint256 rewardAmountErc20 = 0;
            address tokenAddress;

            if (ethWageredSinceLastReward[currentPlayer] >= rewardsInfo.thresholdEth) {
                rewardAmountEth = ethWageredSinceLastReward[currentPlayer].mul(rewardsInfo.rewardPercentage).div(10000); // Convert basis points to percentage
                ethBalances[currentPlayer] = ethBalances[currentPlayer].add(rewardAmountEth);
                ethBalances[HOUSE_ADDRESS] = ethBalances[HOUSE_ADDRESS].sub(rewardAmountEth);  // Deduct from house balance
                ethWageredSinceLastReward[currentPlayer] = 0; // Reset the wagered amount for ETH
                
                leaderboard[currentPlayer].totalEthRewards = leaderboard[currentPlayer].totalEthRewards.add(rewardAmountEth); // Record the ETH reward
            }

            for (uint256 i = 0; i < allowedTokenAddresses.length; i++) {
                tokenAddress = allowedTokenAddresses[i];
                if (erc20WageredSinceLastReward[currentPlayer][tokenAddress] >= rewardsInfo.thresholdErc20) {
                    rewardAmountErc20 = erc20WageredSinceLastReward[currentPlayer][tokenAddress].mul(rewardsInfo.rewardPercentage).div(10000); // Convert basis points to percentage
                    tokenBalances[currentPlayer][tokenAddress] = tokenBalances[currentPlayer][tokenAddress].add(rewardAmountErc20);
                    tokenBalances[HOUSE_ADDRESS][tokenAddress] = tokenBalances[HOUSE_ADDRESS][tokenAddress].sub(rewardAmountErc20);  // Deduct from house balance
                    erc20WageredSinceLastReward[currentPlayer][tokenAddress] = 0; // Reset the wagered amount for this ERC20 token
                            
                    leaderboard[currentPlayer].erc20Rewards[tokenAddress] = leaderboard[currentPlayer].erc20Rewards[tokenAddress].add(rewardAmountErc20); // Record the ERC20 reward

                    // Update the total ERC20 rewards for this token
                    leaderboard[currentPlayer].totalErc20Rewards[tokenAddress] = leaderboard[currentPlayer].totalErc20Rewards[tokenAddress].add(rewardAmountErc20);
                }
            }

            emit RewardClaimed(currentPlayer, rewardAmountEth.add(rewardAmountErc20));
        }
    }


    function withdrawERC721(address tokenAddress, uint256 tokenId) external {
        require(IERC721(tokenAddress).ownerOf(tokenId) == address(this), "The contract does not own this token");
        require(allowedERC721s[tokenAddress], "Token not allowed");
        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawERC1155(address tokenAddress, uint256 tokenId, uint256 amount, bytes calldata data) external {
        require(allowedERC1155s[tokenAddress], "Token not allowed");
        require(IERC1155(tokenAddress).balanceOf(address(this), tokenId) >= amount, "Not enough tokens to withdraw");
        IERC1155(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId, amount, data);
    }

}