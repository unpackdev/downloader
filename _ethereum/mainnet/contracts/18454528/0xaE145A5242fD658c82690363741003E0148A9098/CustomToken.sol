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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: yoooooooooooo.sol


pragma solidity ^0.8.20;


    /* 
                                                YOOOOOOOOOOOOOOOOO
    		telegram: t.me/yooooooooo000000000
	    website: yoooooooooooooooooo.wtf
   twitter: https://twitter.com/ELONMUSK
   
7777777777777777777777777777YJJJJJJJJJJJJJJJJJJJJJJJJJJJJ555555555555555555555555555555555555Y777777
7777777777777777777777777777YJJJJJJJJJJJJJJJJJJJJJJJJJJJJ555555555555555555555555555555555555Y777777
7777777777777777777777777777YJJJJJJJJJJJJJJJJJJJJJJJJJJJJ555555555555555555555555555555555555Y777777
7777777777777777777777777777YJJJJJJJJJJJJJJJJJJJJJJJJJJJJ555555555555555555555555555555555555Y777777
77777!~~!77777~^~!77!~~^~~!?YYJ?7!!!7?JJJJ?7!!!7?JJJJ?7!!7?J5555YJ?77?J55555J?77?JY5555Y?777?J777777
7777:^YY^:!7~.!Y?.::!?Y5J!:^J!:~?Y5Y7^^?7^^7Y5Y?^^??^^7J5Y?~^?Y~^!JY5J!:7Y!^!?Y5J7^!Y7^~?Y5Y7^:!7777
7777.^&@&7.^ J@@P ~B@@BG&@B^ ^P@@BG&@#! .5@@#G#@&? .J&@&GB@@Y..7#@&GG@@G:.~B@@GG&@B^.:P@@BG#@&!.!777
77777::G@@J Y@@P :&@#^:.^@@P B@&!:^.#@# 5@@?.^ G@@:?@@5.^ Y@@!~@@G:~.7@@J:&@#^^:^&@P B@&!:^.#@#.^777
777777^.5@@B@@5. ~@@P ^.^&@5.&@B ^^.#@B.B@&::~ P@&:5@@! ! J@@~7@@J 7.!@@?^@@P !:^&@P.&@# ~~.B@#.^777
7777777~ Y@@@5 ~~.5@@GY5&@B: ?@@BYY#@#~ !&@#YYB@&7 ^B@&5YG@@Y .G@@PYP@@P. Y@@GY5&@B: ?@@BYY#@#~.!777
7777777~ J@@5 ~77~:~YGGG57:~?^^JPGG5?:~?^^?PGGP?^^?~:75GGPJ~^J7:!YGGGY!:??^~YPGG57:!J^~JPGG5?^:77777
777777! ?@@5 ~?????!~~~~~!7?YY?!~~~!7?JJJ?7!~~~!?JJJJ7!~~!7J5555J7!!!7J5555J7!!!7?Y555J7!!!!?J777777
777777::&@G.^JJJYJJYYYYYYYYYYYJYYJJJJJJJJJYYYYYYJJJJJJJJY555555555555555555555555555555555555Y777777
777777~:~!:^7?JJJJJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYY555555555555555555555555555555555555Y777777
77777777!!777?JJJJJJJJJJJJJJJJJJJJJJJJYYYYYYYYY55555YYYY55PPPPPPPPP55555PPPPPPPPPP55555555555Y777777
7777777777777?JJJJJJJJJJJJJJJJJJJJJJYYYYYY555555YYJ777777777777777777777777777777777777777?JJJ777777
7777777777777?JJYYJJJJJJJJJJJJJJJJYYYYYYY55555YYJJJ7777777777!!!!!!!!!!!!!!!!!!!!!!!!!!777?JJJ777777
7777777777777?JJYYJYYYYYYYYJYYYYYYYYYYYY5555555YYJJ777777777777777777777!!!7777777!!!77777?JJJ777777
77777!^^!777?7!!7JYJ?7!!!7JYYYY?7!!!7J5555Y?7777?JJ77!~^^^~!7777!~^^^^~!777!~~^^^~!7777!~~~!7?777777
7777:^YY^:!?!.75?.^^!J55Y7:~J7^~J55Y?^^Y?^~?Y55?~:7!:^7Y55J~.~!::7Y55Y!:^!^:!J55Y7::!^:~J555?^:!7777
7777:^#@&7.^ Y@@P ~B@@GP&@#^ ^G@@GP#@&! :5@@BPB@@J .Y&@#PG@@5. ?#@&PG@@G: !B@@GP&@#^ ^G@@BP#@&!.!777
77777::G@@Y Y@@5 ^&@B:^:^&@P.B@&~:^.#@# P@@7.~ P@@:?@@Y.: J@@!~@@P.: !@@J:&@#::.^&@P B@&~.:.#@#.^777
777777^.5@@B@@5. ~@@P ~:^&@5.&@B ^^.#@B.B@&:.^ P@&:5@@! ^ Y@@~7@@J ^ 7@@?^@@P :.^&@5.&@#.::.#@B !YYY
7777777~ J@@@Y 7! Y@@GYP&@G: ?&@B55#@#~ ~#@#55B@&7 ^B@&PYG@@J .P@@GYG@@5. Y@@BYP&@G: ?&@#55#@#~:Y555
7777777~ Y@@Y !YJ7:~JPGPY!:!7^^?5GG57:^!::75GG5?^^?^:7YGGPJ^:~~:!YPGPJ~.~~:~JPGPY!:^!:^?5GG57^!Y5555
777777! J@@5 !JJJJJ7!~~~!7?JJJ?!~~~!~!777!~^^^^~7JY7!~^^^^~!7777~^^^^^~7777!^^^^^~77??7!~~!7JP555555
777777::&@G.^?JJYYYYYYYYYYYYYYYYYYYY7!!!!77777777JJ77777777777777777777777777777777????JJYYPPG555555
777777!:~!:^7?JJY55555555555555555557!!!!777!!7777777777777777777777777777777777??JYY55555Y?JG555555
77777777!!777?JJY55555555555555555557!!!!7777777777777777777777777777777777777777?JYY5Y555J7?G555555
7777777777777?JJY55555555555555555557!!!!7777777777777777777777777777777777777777?JYY55555Y?YG555555
7777777777777?JJY55555555555555555557!!!77777777777777777777777777777777777777777?JY5555PPGGGG555555
7777777777777?JJ55555555555555555555?!!777777777777777777777777777777777777777777?JY5PPPGBBBBG555555
77777!^^~777?7!~7Y5YJ77!7?Y5555J77!77?YYYYJ7!!!7?YYYYJ7!!!!?YYYYJ7!!!!7JYYYY7^^^~!J5PPP5J??JYP555555
7777:^55~.!?~.7PJ.^^7YPP5?^~Y7^!J5P5?^^J?^~J5PPJ~^JJ^~?5PPY!:?J~^7YPPY7:!Y!^7YPP5?^~5?^!J5P5?^^J5555
!!!!:^#@@?.: Y@@5 !#@&PP&@#~ ^B@@G5#@&7 :P@@B5B@@J .Y@@B5G@@P. ?&@#PP&@B: !#@&P5#@#~ ^B@@G5B@&7.!7!!
!!!!!:.P@@Y.5@@5 ^@@B:~::&@P.#@&~^~.#@#.P@@7:! P@@:J@@J.! J@@!!@@P.~.!@@J:&@B:!~:&@G.B@&~.:.B@#.:!!!
!!!!!7^.Y@@#@@Y  ~@@P !:~@@5.&@#.^^:#@B B@&^:!.G@&.5@@!.! Y@@~7@@J !.7@@?^@@P 7^^&@5.&@#..::#@B ^!!!
!!!!!!7~ J@@@Y ~!.J@@B5G@@P: 7&@#5P&@B^ ~#@&P5#@#! :G@@G5B@&? .5@@G5G@@Y..J@@B5P@@G: 7&@#PP&@B^.!!!!
!!!!!!7~ Y@@Y ~7YJ^~?5PPJ!^7Y~^?5PPY!^!Y!^7YPP57^~Y7^!YPP5?^^J?^~J5P5J~^Y5~~?5PPJ!:^~:^75PPY!::!!!!!
!!!!!!~ J@@Y ~77J55Y?777?J5555Y?7777JY555YJ7777?Y5555J7777?Y5555Y?77?J5GGGBPYJJJ~~!!!!!^^^^^~!!!!!!!
!!!!!!::&@P ^777J55555555555555555555555555555555555555555555555PPPPGGGGGGGBB##B?!!!!!!!!!!!!!!!!!!!
!!!!!!~:^~:^7777J55555555555555555555555555555555555555555555555PPPPPGGGGGGGBBBG7!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!77777J5555555555555555555555555555555555555555555555PPPPPGGGGGGGBBBGJ7!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!7777J555555555555555555555555555555555555555555555PPPPPPGGGGGGGGB#GJ7!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!7777J5555555555555555555555555555555555555555555PPPPPPPGGGGGGGGGB#GJ7!!!!!!!!!!!!!!!!!!!
7777777777777777J5555555555555555555555555555555555555PPPPPPPPPPGGGGGGGGGGGBB#BY7777!!!!!!!!!!!!!!!!

    */
    
contract CustomToken is ERC20 {
    address public owner;
    address public taxAddress; 
    mapping(address => bool) public blacklist;
    mapping(address => bool) public antiWhaleWhitelist;
    uint256 public taxPercentage;
    uint256 public whaleLimit; 
    address public uniswapPair; 
    bool public restrictContracts; 
    bool public tradingEnabled = false;

    constructor() ERC20("yoooooooooooooooooo", "YOOOOOOOOOOOOOOOOOO") {
        owner = msg.sender;
        _mint(msg.sender, 1_000_000 * 10 ** 18); 
        whaleLimit = totalSupply() / 100; 
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

    function startTrading() external onlyOwner {
        tradingEnabled = true;
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