// SPDX-License-Identifier: MIT LICENSE
// File: https://github.com/chiru-labs/ERC721A/blob/main/contracts/IERC721A.sol


// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// File: contracts/uwastake2.sol



pragma solidity ^0.8.4;





contract PixelToken is ERC20, Ownable {
  using SafeMath for uint256;

  mapping(address => bool) controllers;

  uint256 private _totalSupply;
  uint256 constant _maxSupply=6000000*10**18;
  
  constructor() ERC20("Pixel", "PXL") { }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require((_totalSupply+amount)<=_maxSupply,"Maximum supply has been reached");
    _totalSupply = _totalSupply.add(amount);
    _mint(to, amount);
  }

  function mintForAddress(address to, uint256 amount) public onlyOwner {
    amount=amount*10**18;
    require((_totalSupply+amount)<=_maxSupply,"Maximum supply has been reached");
    _totalSupply = _totalSupply.add(amount);
    _mint(to, amount);
  }

  function burn(uint256 amount) public{
    amount=amount*10**18;
    require (balanceOf(_msgSender()) >= amount,"Not enough Balance!");
    _totalSupply = _totalSupply.sub(amount);
    _burn(_msgSender(), amount);
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }

  function maxSupply() public  pure returns (uint256) {
    return _maxSupply;
  }
}



contract PXLStaking is Ownable, IERC721Receiver {

  uint256 public totalStaked;
  uint256 public rewardDay = 3;
  
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }
  struct Stake2 {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }
  struct Stake3 {
    uint24 tokenId;
    uint48 timestamp;
    address owner;
  }

  event NFTStaked(address owner, uint256 collId, uint256 tokenId, uint256 value);
  event NFTUnstaked(address owner, uint256 collId, uint256 tokenId, uint256 value);
  event Claimed(address owner, uint256 amount);

  // reference to the Block NFT contract
  IERC721A genesis;
  IERC721A reloaded;
  IERC721A butterfly;
  PixelToken token;

  // maps tokenId to stake
  mapping(uint256 => Stake) public vault; 
  mapping(uint256 => Stake2) public vault2;
  mapping(uint256 => Stake3) public vault3;

   constructor(IERC721A _genesis, IERC721A _reloaded, IERC721A _butterfly, PixelToken _token) { 
    genesis = _genesis;
    reloaded = _reloaded;
    butterfly= _butterfly;
    token = _token;
  }

  function stake(uint256[] calldata collIds, uint256[] calldata tokenIds) external {
    uint256 tokenId;
    uint256 collId;
    totalStaked += tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      collId = collIds[i];
      if(collId==1){
        require(genesis.ownerOf(tokenId) == msg.sender, "not your token");
        require(vault[tokenId].tokenId == 0, 'already staked');
        genesis.transferFrom(msg.sender, address(this), tokenId);
        vault[tokenId] = Stake({
          owner: msg.sender,
          tokenId: uint24(tokenId),
          timestamp: uint48(block.timestamp)
        });
        emit NFTStaked(msg.sender, collId, tokenId, block.timestamp); 
      }else if(collId==2){
        require(reloaded.ownerOf(tokenId) == msg.sender, "not your token");
        require(vault2[tokenId].tokenId == 0, 'already staked');
        reloaded.transferFrom(msg.sender, address(this), tokenId);
        vault[tokenId+427] = Stake({
          owner: msg.sender,
          tokenId: uint24(tokenId+427),
          timestamp: uint48(block.timestamp)
        });
        emit NFTStaked(msg.sender, collId, tokenId, block.timestamp); 
      }
      else if(collId==3){
        require(butterfly.ownerOf(tokenId) == msg.sender, "not your token");
        require(vault3[tokenId].tokenId == 0, 'already staked');
        butterfly.transferFrom(msg.sender, address(this), tokenId);
        vault3[tokenId] = Stake3({
          owner: msg.sender,
          tokenId: uint24(tokenId),
          timestamp: uint48(block.timestamp)
        });
        emit NFTStaked(msg.sender, collId, tokenId, block.timestamp); 
      }
    }
  }

  function _unstakeMany(address account, uint256[] calldata collIds, uint256[] calldata tokenIds) internal {
    uint256 tokenId;
    uint256 collId;
    totalStaked -= tokenIds.length;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      collId = collIds[i];
      if(collId==1){
        Stake memory staked = vault[tokenId];
        require(staked.owner == msg.sender, "not an owner");

        delete vault[tokenId];
        emit NFTUnstaked(account, collId, tokenId, block.timestamp);
        genesis.transferFrom(address(this), account, tokenId);
      }else if(collId==2){
        Stake2 memory staked2 = vault2[tokenId];
        require(staked2.owner == msg.sender, "not an owner");

        delete vault2[tokenId];
        emit NFTUnstaked(account, collId, tokenId, block.timestamp);
        reloaded.transferFrom(address(this), account, tokenId);
      }else if(collId==3){
        Stake3 memory staked3 = vault3[tokenId];
        require(staked3.owner == msg.sender, "not an owner");

        delete vault3[tokenId];
        emit NFTUnstaked(account, collId, tokenId, block.timestamp);
        butterfly.transferFrom(address(this), account, tokenId);
      }
    }
  }

  function setRewards(uint256 _rewardDay) public onlyOwner {
    rewardDay=_rewardDay;
  }
  function claim(uint256[] calldata colIds, uint256[] calldata tokenIds) external {
      _claim(msg.sender, colIds, tokenIds, false);
  }

  function claimForAddress(address account, uint256[] calldata colIds, uint256[] calldata tokenIds) external {
      _claim(account, colIds, tokenIds, false);
  }

  function unstake(uint256[] calldata colIds, uint256[] calldata tokenIds) external {
      _claim(msg.sender, colIds, tokenIds, true);
  }

  function _claim(address account, uint256[] calldata collIds, uint256[] calldata tokenIds, bool _unstake) internal {
    uint256 tokenId;
    uint256 collId;
    uint256 earned = 0;
    uint256 rewardmath = 0;
    uint256 totalnfts = 0;
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      collId = collIds[i];
      if(collId==1){
        Stake memory staked = vault[tokenId];
        require(staked.owner == account, "not an owner");
        totalnfts=totalnfts+1;
        vault[tokenId] = Stake({
          owner: account,
          tokenId: uint24(tokenId),
          timestamp: uint48(block.timestamp)
        });
        uint256 stakedAt = staked.timestamp;
        rewardmath = 100 ether * rewardDay * (block.timestamp - stakedAt) / 86400 ;
        earned = earned+(rewardmath / 100);
        
      }else if(collId==2){
        Stake2 memory staked2 = vault2[tokenId];
        require(staked2.owner == account, "not an owner");
        totalnfts=totalnfts+1;
        vault2[tokenId] = Stake2({
          owner: account,
          tokenId: uint24(tokenId),
          timestamp: uint48(block.timestamp)
        });
        uint256 stakedAt = staked2.timestamp;
        rewardmath = 100 ether * rewardDay * (block.timestamp - stakedAt) / 86400 ;
        earned = earned+(rewardmath / 100);
      }else if(collId==3){
        Stake3 memory staked3 = vault3[tokenId];
        require(staked3.owner == account, "not an owner");
        totalnfts=totalnfts+1;
        vault3[tokenId] = Stake3({
          owner: account,
          tokenId: uint24(tokenId),
          timestamp: uint48(block.timestamp)
        });
        uint256 stakedAt = staked3.timestamp;
        rewardmath = 100 ether * rewardDay * (block.timestamp - stakedAt) / 86400 ;
        earned = earned+(rewardmath / 100);
      }
    }
    uint256 rewardMultiplier = 0;
    if(totalnfts==1) rewardMultiplier=0;
    else if(totalnfts==2) rewardMultiplier=10;
    else if(totalnfts==3) rewardMultiplier=20; 
    else if(totalnfts==4) rewardMultiplier=30; 
    else if(totalnfts==5) rewardMultiplier=40;
    else if(totalnfts>=6) rewardMultiplier=50;

    if (totalnfts>0 && earned > 0) {
      earned=earned+(earned*rewardMultiplier/100);
      token.mint(account, earned);
      emit Claimed(account, earned);
    }

    if (_unstake) {
      _unstakeMany(account,collIds, tokenIds);
    }
  }

  function earningInfo(address account, uint256[] calldata collIds, uint256[] calldata tokenIds) external view returns (uint256[1] memory info) {
     uint256 tokenId;
     uint256 collId;
     uint256 earned = 0;
     uint256 rewardmath = 0;
     uint256 totalnfts = 0;
     
    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      collId = collIds[i];
      if(collId==1){
        Stake memory staked = vault[tokenId];
        require(staked.owner == account, "not an owner");
        uint256 stakedAt = staked.timestamp;
        rewardmath = 100 ether * rewardDay * (block.timestamp - stakedAt) / 86400 ;
        earned = earned+(rewardmath / 100);
        totalnfts=totalnfts+1;
      }else if(collId==2){
        Stake2 memory staked2 = vault2[tokenId];
        require(staked2.owner == account, "not an owner");
        uint256 stakedAt = staked2.timestamp;
        rewardmath = 100 ether * rewardDay * (block.timestamp - stakedAt) / 86400 ;
        earned = earned+(rewardmath / 100);
        totalnfts=totalnfts+1;
      }else if(collId==3){
        Stake3 memory staked3 = vault3[tokenId];
        require(staked3.owner == account, "not an owner");
        uint256 stakedAt = staked3.timestamp;
        rewardmath = 100 ether * rewardDay * (block.timestamp - stakedAt) / 86400 ;
        earned = earned+(rewardmath / 100);
        totalnfts=totalnfts+1;
      }
    }
    uint256 rewardMultiplier = 0;
    if(totalnfts==1) rewardMultiplier=0;
    else if(totalnfts==2) rewardMultiplier=10;
    else if(totalnfts==3) rewardMultiplier=20; 
    else if(totalnfts==4) rewardMultiplier=30; 
    else if(totalnfts==5) rewardMultiplier=40;
    else if(totalnfts>=6) rewardMultiplier=50;
    if (totalnfts>0 && earned > 0) {
      earned=earned+(earned*rewardMultiplier/100);
      return [earned];
    }
}

  // should never be used inside of transaction because of gas fee
  function balanceOf(address account) public view returns (uint256) {
    uint256 balance = 0;
    uint256 supply = genesis.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      if (vault[i].owner == account) {
        balance += 1;
      }
    }
    supply = reloaded.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      if (vault2[i].owner == account) {
        balance += 1;
      }
    }
    supply = butterfly.totalSupply();
    for(uint i = 1; i <= supply; i++) {
      if (vault3[i].owner == account) {
        balance += 1;
      }
    }
    return balance;
  }

  // should never be used inside of transaction because of gas fee
  function tokensOfOwner(address account, uint256 collId) public view returns (uint256[] memory ownerTokens) {
    if(collId==1){
      uint256 supply = genesis.totalSupply();
      uint256[] memory tmp = new uint256[](supply);
      uint256 index = 0;
      for(uint tokenId = 1; tokenId <= supply; tokenId++) {
        if (vault[tokenId].owner == account) {
          tmp[index] = vault[tokenId].tokenId;
          index +=1;
        }
      }
      uint256[] memory tokens = new uint256[](index);
      for(uint i = 0; i < index; i++) {
        tokens[i] = tmp[i];
      }
      return tokens;
    }else if(collId==2){
      uint256 supply = reloaded.totalSupply();
      uint256[] memory tmp = new uint256[](supply);
      uint256 index = 0;
      for(uint tokenId = 1; tokenId <= supply; tokenId++) {
        if (vault2[tokenId].owner == account) {
          tmp[index] = vault2[tokenId].tokenId;
          index +=1;
        }
      }
      uint256[] memory tokens = new uint256[](index);
      for(uint i = 0; i < index; i++) {
        tokens[i] = tmp[i];
      }
      return tokens;
    }else if(collId==3){
      uint256 supply = butterfly.totalSupply();
      uint256[] memory tmp = new uint256[](supply);
      uint256 index = 0;
      for(uint tokenId = 1; tokenId <= supply; tokenId++) {
        if (vault3[tokenId].owner == account) {
          tmp[index] = vault3[tokenId].tokenId;
          index +=1;
        }
      }
      uint256[] memory tokens = new uint256[](index);
      for(uint i = 0; i < index; i++) {
        tokens[i] = tmp[i];
      }
      return tokens;
    }
  }

  function onERC721Received(address, address from, uint256, bytes calldata ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send nfts to Vault directly");
      return IERC721Receiver.onERC721Received.selector;
    }
  
}