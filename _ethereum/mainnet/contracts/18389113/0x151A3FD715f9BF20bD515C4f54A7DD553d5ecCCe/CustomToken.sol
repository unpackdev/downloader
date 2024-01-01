// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: obama.sol

pragma solidity ^0.8.20;



/// THE ORIGINAL OBAMA COIN
/// telegram: t.me/tickerobama
/// website: tickerobama.org
/// twitter: https://twitter.com/BitcoinObama/status/1708414123644510661
/// twitter archive: https://archive.ph/F0I9D
  
  
    /**
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##########BGGP555G####&&&######&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###########B#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###BB##BBGP55YYYYYYYYY5Y5PGB###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BP5YJJJYYYYYY555PPPPP5555PP5YYJYY5PG##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&B5YJ?J?JJJJJYYYJJYYYYYYY55YYYYYYY555555YYJJ5G#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BBGGP5YYYYYJJY55555555YYYYYJJJJJ??????JJJJJYYYYYYY5555J?J5G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BGP5YYYY5PPPPPPPGGGGGPPPPPPPP55555555YYYJJ??????JJJJJJJYYYJYY5YJYPB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GPJ?JY55PPPPPPP5PPPPPPPPPP555555YYYYJJJJYYYYYYYYJJ?777????JJJJJYYYYJ??YB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BPYJJYY55PP5555555YYYYYY555555YYYYJJJ????????JJJJJJJJYJJ?7!!!7?????JJJJJJJ??YB&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BPJ?JY5PPPPPPPPPPPP5555YJJY555YYJJ????777777?????????????JJJJ?7!~~!777????JJJJ?7?G&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BG5Y?YPPGGGPP55PPGGGGPPPPP55YYYYJJJ??????777777??7777!!7!!!777??JJJ?!~~!777?????????7P#&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###BBGGPP5Y5PGGGGGGGGGGPPGGGGGGPP55YYYYYYYJJ?????????7?777777!~~~^^~~~~!!77??JJ7~~~!!7777??????7JB&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&&B5JJYJJY5PGGGGGGGGGGGGGGGGGGGGGP55YYJJJYYYJJJJJJ??????????777!~~~~^^^^:^^^~!!77???!~~~!!77?7777??7JG#&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#######BBBB####&&&&&&&&#BBPY?JY5PPGGGGPGGGGGGGGGGGGGGGGGGP55555YYJJ???77??JYJ??777?????77!!~~~~~~~^:::^^~~!!7??7!~~~!!7777777?77P&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BPPGP5555555555YY5GGGGBBGPYJJY5PPPGGGPPPPPPPPPPP5PPPPPGGPP5YYYYJJYY5P5YJ7!!!7JJJJ?7777???777!!~~~~~~^^::.:^^~~!7???7!~~~!!!!77777!7P########&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#5P###BGGGPGGPPP55YYJ???77?5GGGGGGGGGPPPPP555555555PPPP55YYYYJJ?????JJ5GP5J7!!?JYYYJJ?7!!7!~~!!!~^^^^^^^:..:^^~~!7???7!~~~~!!!777777!JB#&#&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BPYG####BGPP55YYYJ?????J5PGGGGGGGGGGGGGGGPPPP5PPP555YYYYJJJJ??7777J?7?YPP5Y?7!?Y55YYJ?7~~~^^^~~~~^^^^^^::::::^^~!7???7!~~~!!!7777777!J#&####&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##GJB&&##BG5JJJ???77?JPBBBGGGGGGGGGGPPP55PPPPPPP55YJJJJ???7!!!!!!!7??!7?Y55YY?77J55YYYJ7~^~~~~~~~~^^^^^^^^::::^~!77????!~~~!!!!!77777!J#####&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##P5PPPPGGP5YYYYYY5PBBBGGGGGGGGGGGGGPPPPPPPP555YYYJJ???77!!~^^^~~!7??!!7J5P55Y??J5555YJ7!~~~~!~~~~^^^^~~~^^^^^~!77???J?!!!~!!!!!!7777!Y#&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BBG5JP##BBBGGGBGGGGGGGGGGGGGGPPPPPPPPP55YYYYYYJJ??77!~~^::^~~~~!?J?77JYP555JJY555YJ?7~^~!!!~~^^^^~~~~~~~~~~!!77??JJ?7!!!!!!!777777!5#&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###P?J5PPGGGGGGGGGGGGGPGGGGGGGPPPPPP555YYYYYYYYYYJJ?77!~~^^^~~!!!!!7??????JJYYYYY5YJJYJ7~^~~~~~~~^^^~!!!!!!!!!!7??JJYY?7!!!!!!!!7777775#&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B5?J5PPPPGPPGGGGGGGGGGGGPPPGGGPPPP5555YYJJJJJYYYJJ??7777777!!~~!7777????777??JJY555J???7!~~~~~^^^^^^~!777777777??JJJYYJ?!!!!!!!!777777!G&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BY?YPPPPPPPGGPPGGGGGGGGGPPGGPGGPPP5YYYYJJJ????JJJ?77!777??JJJ??7!!777777????J?JJYYYYJJ7!!!!!!!!~~~!!!!77????????JJJJYY5Y?7!!!!!77777777!7B&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GYJ55PPPPPPPPPPPPPPP5555PPPPPPPPPPP5YYYYJJJ???????777!!!!!!!!!!7???777!!!!77????????!^~?YYYJJJJ???7!!77???JJJJJJJJYYYY555Y?7!!!!!77777????7G&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&#GY?Y555555555555555555YYYY5PPPPP5YJY55YYYJJJJ?????J????????77!!!77??????7777??77!!!!!~~!?J5PGPP5555YYJ???7?JJYYYYYYYYYY55PPY?7!!!!!777777???!Y&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BG5J?JYYYYYYYYYY5YY55YY55555555555YJ??JY5YYYYJJJJ?JJYYYJJJ????????JYYJ????????????777!~~!7?JY5PGGPPPPPPP5YYJJ??JYYYYYYY55555PPPY7777777777777?7?!P&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#P??JYY5YYYYYYYYYYYYYJJ?JJJJJJJYYYYJ??YYY5YYYYYJJJJJYYYYY77????7777YPG5Y???7!!~~^^!777!!7??JYY55555YYYY5PPP5YYJJYYYYYYY5555PPPGPJ777777777777????!G&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&G5JJYYY55YYYYYYYYJJYJJJ??????777?????JJJJ??JYYYJJJJJJJJYYYJ7!!!!???!^^75GPYJ?!~:.   :~!77??JJJYYYYY55555YJY5P5Y55YJYYYYYYYY55PPGGY77777777777777???!G&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BGY?JY55YY5555YYJJYYYYYJJJJ??????7777777777!~7?!7?JJJJJJ?JJY??7!!!~7???!:.!5G5J?7!!~^:..:!7?JJJYYYYYJJYY55YYYJJY55555YYYYYYYY55PGGGY?7777777777777???7!#&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BBPYJJY5555555555YYYYYYYYYYYYJJJ?????777!!!777!!~^::^!JJJJ??JJJ?77~^~~!????7^:755YJ???7!!~~!7?JYYYYYJJJ?77?5P5YYYJJYYPGP5YYY555PPGGGGY?77777777777777???!J#&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##P?7J55PPPPPP5555YYYYYYYYYYYYJJJJJJ?777!!!!!!!!!!!~^^^^^7?JJ?JJJ?77~^~~!7??JJ?~^!Y55YJ???77???JYYYYJJJYJJ?77?JPGP55JJJYPGPYY5PPPGGBGPJ7777777777???77????~P&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&###G7?YY5PPP5P555555YYYY555YYYJJJJJJ???77777!77!!~~~~!!~^~~~~7???JJ7!!!~^^~77?JJJ?!~~?Y55YYYJJJJJJYYYYJJJ??JJJ???JPGGG5YY5PGP5PGGBBBGPY?777777777??????????77B&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&#B57?Y55PPPPPP5555555555555YYYYYYYJJ?????777777!!~~~~~~!~~~^^^!??JJ?!~~^::^!7?JJJJJ?7~~7YPGGPP5YYYYJYY??7!!7??JJJJJ5GBG5Y5GGGGGBBBB5J?7777777777??????????77G&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&G?7J55555555555555Y555YYYYYYYYYYYYYJJJJJ?????77!!!~~~~~~~~^^^^^~7?JJ?7~~^^^~~!7?JJJJJ?7!!7YGBBGP5YYJJJ?7!~~~!!7??JJJYPBP55GBBB##GY?!!7777777777???????????!JB&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&GJJ5PP555555555555555YY5YYYYYYYYYYYJJJJJJ?JJ???77!!!~^~~~~~~~~~^^^~7JYJ?!~~^:^~~!7?JJJJJJ??7J5GGGPY?7777!!~~~!!!7??JYJ5PPPPG##BPJ7!!777777777777????????????P#&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&BG55PPP555YYY555YYYYYY5YYYYYYYYJJYYYYJJ??7?J??JJ???77!!!~~~^~~~~~~~^^^~!?JYY?7!~^:.^!~!777?JJJ???Y5PY?7!77!~~^~!!777?JYYY5PGGGGPJ7!777!!7777777777777????????7Y###&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&#####BP5Y5PPP55YYYYYYYYYYYYYYYYYYYJJJJJJJYYJJ77??77?JJJJ?77?77!!!!!~~~~~~~~~^^^^~!?YYJ?7~~~!!~^~^^~!?????JYYJ?7777!~~!77???JYY5PGBGP5J7!!!777???77?777777777????????7?B#BB#&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&###G5YYPP55555YYYYJJYYYYYYYYYYYYYJJ??JJJJJJJ?!?JJ77?J??JJ???777!~!!!~~~~~^^^~~~~~~!?JYYY?77!!!!!~~~!!77??JJJ?7777777????JJY55PPP5J?77!7777777?J??7???7777?????????J??G#####&&&&&&&&&&&&&
&&&&&&&&&&&##BG5555Y5P5555YY5YYYYYJJJJJJJJJYYYYJJ??????????????7?JJJJJ???J???77!!!!!~~~~~^^^^~~~~~~!7JYYYYJJ?????JJJ77?JY5YJ??????JJJJYY55PPPPY?777!!!7777777?J?????777777???????J?75&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&G?PP555PP555YYYYYYYYYYYJJJJJ??JJJYYYJJJJJJJ??77~!!7JJJJJ??77???J???777!!!!~~~~^~~~~~~~~~~~!?JYYY5555555PP555PPP5YYYYYYY5555PPPGGPY?7!777!!!!777777?????7777777???????J?7Y###&&&&&&&&&&&&&&&&&
&&&&&&&&&&&#YYPP555Y555YYYYYYYYYYYYYYYJJ??JJJJJJJJJJJJJ??7!!7JJJJ?7JJ!~!?????7777!!!!!!!~~~~~~~~~~~~~~~7JJYY555555PPPGGGGPP5555PPPPPPGGGG5J7!!7777!!77777777????????JJJ?????????7JG###&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&#PYY555YYYYYYYYYYYYYYYY555YYYYJJJJJJJJJJ??????????JJJJ77??!^~!777!!77!!!!~!!!~~~~~~~~~~~~~~~!?YYYY555PPPPGGGGPPPPPPPGGGBBBPY?7!777777777777777???JJ?????JJJ?????????5B###&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&#&B5JY5YYJYYYYYYYYYYYY555555PPPP55YJJJJJ?????????JJJJJ?7777777777777!!!!!~~~~~~~~~~~~~~~~~~~~!7Y555PPPGGGGGGPPPPGGGBB##G5?7777777777777777777???JJJ?????????????J?7YGB##&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&GJJ5YYYYYYYYYYY5555555PGGBBBBGP5YJJJJ??77???77?JJ?77777??????777!!!!!!~~~~~!~~~~~~~~~~~~~!!!JPGGGGGGGGGGGGBBB###BPJ77777777777777777777??????J?????7???????77YPGB#&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&BJJYY5YYYYY5555555Y55PPGBBBBBBGP5JJ???77777777777777777?????777!!!!!~~~~~~~~~!~~~~~~~!!!!!!!75PGGGGGBBBBB##BGPY?777777777777777777777???????????????????77JG#&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&##&B?Y5555YY55555555PGGP5PPGGBBBBBGP5J?777!!!!!!!!!777777777777777!!!!!~!!!!~~~~~~~~~~!!!!!!!!!!?PGBBG5YJJJYJ??77777777777777777777777??????????????????77YG###&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&#B#G?YYY555555P55PPGGG5YY555PPGGBBBBBPJ?7!!!!!!!!!!!77777777777777!!!!!!!!!!!~~~~~!~~~!!!!!!!!!!!7YYJ?7!777777777?7777777777777777?????????????????????77G#####&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&###?7YY5P555PPPPGBGP55YYYYYY5555PGGBBBPJ?777!!!!!!!!7777777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!77777777777777777777777??77777777???????????????J????7JB######&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&#?7YY5PP5PPGBBBP55Y5YYY5YYYYYY5Y5PGBBPJ?777!!!!!!!!777777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!777777777777777777??J??77777777777?????????????????77PGB##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&B7?Y55555PP5PP555555YY5555YYYYYY55PGBG5J?777777!!77777777777777!!!!!!!!!!!!!!!!!!!!!!!!!!7777!!777777777777777?JY55YJ???????????????????????????77YGBBB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&#P!JYY5555P55P555P555555555555555555PGBG5J???777!!777!7!!777!!77!!!!!!!!!!!!!!!!!!!!!7!!!77777777777777777777?JY555YJJJJJJJJ????????????????????J5GBBBBB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&#5!JYY5YY5P55PP55PP55555555555555555PGBBG5YJ??777777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777777777777777777?JY5YJJ??????????JJJYYYJ???????????JP###BB###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&##5!JYYYYY555YYPGP55555555P555555Y55PPPGBBBP5YJ???7777777!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777777777777777777777?Y5YYJ??????7777777?JJ55J?????????JG####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&#BJ7YYYYY5555YYYPGPP5555PPPP5555555PPPPPGGGBBG5YJ?777777777!!!!!!!!77!!!!!!!!!!7777777777777???77777777777?Y55YY5PPYJ???777777??JY5J???????YG##BB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&B7?JJYY5P5555YY5GGPPP555PP555PPPPPPPP5PGGBBBBBPY????77777777777777777777!7!77777777777??????????????7??77?YPPP5Y5GGY???777?77???JYJ???7YPGB&&#####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&P7??JYY5PPPPP5YY5GGGPP55PPPPPPPPGPPPPPPGGBBBBBBPYJ????777777777777777777777!777777777777????????????????777???77?PGY?77777777??JJY???JP#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&#Y7??JJYY5PPGGP5555PGGP555PPPPPPGGGPPPPPPPGGGBBBBGY?????7777777777777777777777777777777??????J?????????????77???7JPGJ77?77??77??JY?JPG###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&P7J?JJYY5Y5PGPPP555PPPPPPPPPPPGGPPPPPPPPPPGGGBBB#GYJJ???777777777777777777777777777777??????JJ??????????????????JPPJ???????????JJ!G#B#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&B7?JJJY55555PPPPP55PPGBBBBBGGGPPPPPPPPPPPGGGGGBBBBGY???????777777777777777777777777777?????JJJJ?????????????????YPPJ?????????JJJ??#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&##?!??JY555555PPGGPGBBBBBB#BBBGGPPPPPPPPPGGGGGGBBBBBPJJJJJ??7777777777777777777777???7???????JJJ?????????????????YP5J?JJJ?JJJJJJJ7J&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&P!??JJYPPPPP5Y5GGGGGGGGBBBBBGGGPPPGGGGGGGGGBBBBB##BPJJJJJ??777777777????7777777???????????JJYJ?????????????????YP5YYYYJJYYYJJYY?G###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&B77JJJY5PPPP5YYPGGGPPPGGGGGBBBGGPPPPPPPPPPPGGGBBBBBGYJJJJJ???????????????????????????????JJYYJ?????????????????YGBGPPP555555P5JP##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&#57JJJY5PPPPPP5555PPPPPPPGGBBBBBGP5555PPPPPPGGGBBBBGPJJJJ????JJJ?????77?????????????????JJJYYJ???????????????????Y55PGGP5PPP55G##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&#??JJY5PPPPPPP55555P55Y555PPPGGBBGPPPPGGGGGGGGGGGBBPYJJ??JYYYJJJ??77777777?????????????JJJJJJ?????????????????7?G#BBBBBBBBBB##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&Y!?JJY5PPPPPPPPP5PPPPPP555555PGGGPPGGGGGGGGGGBBBBBGYJ?JY55YYJJJ????7777777???????????JJ??JYJJ????????????????YB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&P!?JJYY55PPPPPP5PPPPPPGPPPPPPPGGGPPPGGGGGGGGGGBBBBPYJY555YYYJ???????7777777?????????????JJYJJ??JJJJ???????7?G##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&##Y7?JJJ55PPPGGGP5PPPPPPPPPPPPPPGGPPPPPGGGGGGGGGBBG5YYPPYJJJJJ??????7777777??????????????JJJJJJJYYJJJJJJ??J5#&##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&BY7JJJY55PPPGBGPPPPPPPPPPPPGGPPGGPPGGGGGGGGGGBBGPY5P5YJJJJJ?????????7???????JJJJJJJ?????JJJY5555YYYJ?YPB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&#&G??YJYY55PGGGGGPPPPPGGGGGGGGGGGGGGGGGGGGGGBBGGP5555YJJJ??????????????????JJYYYJJ????JJYY5PPP55555PPB#BB#&&&&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&BY?JYYY55PPGGBGP5PPGGGGGGGGGGGGGGGGGGGGGGGGGPPP5YJJ???????????????????JJY5YYJJ????JJYY5PPGGGGB##&&##B##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&GJ?JYY55PGGGBGGPGGGGBBBGGGGGGGGBBBBBBGGPP55YYYJJ??????????????????JJY5YJJJ?????JPGB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&#PJJYY55PPGGGGGPGGGBBBBBBBBBBBBGGP55555YYYYJYJ??????????????????JYYYJ???????JPBB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&#PYJY555PPPGGGGGGGGGGGBBGGGGGPP5555YYYYYYYJJ?????????????????JY5J??J??YY5G#&BB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GJJY55PPPGPPPPPGGGGGGGGGPPPP555YYYYYYJJJJ???????????????JYP5YJJJYG#&#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GPYJY555555YYYYYYYY55555555YYYYYYYYYYJJ???????????????J55JJYPBBBB###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BYJ555YYJJ??????????JYYYJJYYYYYYY5YJJJ???????????JJ55J5B######&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BPJJ555YYJJJJJ?????JJJJJJYYYYYYYYYYJJ?????JJJJJJ5PJ5##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#PYYY555555YYJJYYYJYYYYYY5555555P5YJJJJJJJJY5P5J5B###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BGPYYY555555555555Y55PPP55555P5YJJY55YY5PPYYG##&&######&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BGPPPPGGGGGGPP5YYGGGGB######G5JY55PBGJ5#&&&&&######&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&#########BGPP555G####&&&######&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
    */


contract CustomToken is ERC20 {
    address public owner;
    address public taxAddress; // Address where taxes will be sent
    mapping(address => bool) public blacklist;
    mapping(address => bool) public antiWhaleWhitelist;
    uint256 public taxPercentage;
    uint256 public whaleLimit; // Will be set to 1% of total supply in the constructor
    address public uniswapPair; // Address of the Uniswap pair for this token

    constructor() ERC20("TickerObama", "OBAMA") {
        owner = msg.sender;
        // Mint initial supply if needed, for example:
        _mint(msg.sender, 1e8 * 1e18); // Example: 100,000,000 tokens with 18 decimals
        whaleLimit = totalSupply() / 100; // Set whaleLimit to 1% of total supply
        // Set initial values for taxPercentage
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function setTaxAddress(address _taxAddress) external onlyOwner {
        taxAddress = _taxAddress;
    }

    function setUniswapPair(address _pair) external onlyOwner {
        uniswapPair = _pair;
    }

    function addToBlacklist(address _address) external onlyOwner {
        blacklist[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyOwner {
        blacklist[_address] = false;
    }

    function addToWhitelist(address _address) external onlyOwner {
        antiWhaleWhitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        antiWhaleWhitelist[_address] = false;
    }

    function setWhaleLimit(uint256 _limit) external onlyOwner {
        whaleLimit = _limit;
    }

    function setTaxPercentage(uint256 _percentage) external onlyOwner {
        taxPercentage = _percentage;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!blacklist[msg.sender], "You are blacklisted");
        require(balanceOf(recipient) + amount <= whaleLimit || antiWhaleWhitelist[recipient], "Recipient would exceed the whale limit");

        uint256 tax = 0;
        if ((msg.sender == uniswapPair || recipient == uniswapPair) && !antiWhaleWhitelist[msg.sender] && !antiWhaleWhitelist[recipient]) {
            // Apply tax only if the transfer involves the Uniswap pair and neither the sender nor recipient is whitelisted
            tax = (amount * taxPercentage) / 100;
            super.transfer(taxAddress, tax); // Send tax to the specified tax address
        }

        super.transfer(recipient, amount - tax);
        return true;
    }

    // Implement other functions like deployLiquidity, etc.
}