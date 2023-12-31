// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;. .cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'      'oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d:.         .,dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk'              .,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                .:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk.                 .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                   .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc                     .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk.                     .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl           ...        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;           .,;,..    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkll'            .;llc::ccdXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMN0000000000000000000000000kl'. ''            .':::;,,;o0000000000000000000KNMMMMMMMMMMMM
// MMMMMMMMMMMWd..''''''''''',,,'''.......    ..             .,::c;. ..'''''''''''''''''.'OMMMMMMMMMMMM
// MMMMMMMMMMMWo ;OKKKKKKK0kl:;,,'..                          .,::l:. .;kKKKKKKKKKKKKKKd..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMXo.                                   .,::ll,..cKMMMMMMMMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMW0;.                                     .,::col'.,kNMMMMMMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMW0,                        .......         .';::ldl..c0WMMMMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMK;                          ......''.        .';::oxc..dXMMMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMx.                                .':,.       ..,::cxd'.;OWMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMx.                                  .lc.        .';::dk:..dNMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMX:                  ...            .:0Xc.         .;::d0: .oNMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMk.                  ';.         .;kNMM0'          .;::kk' .xWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMK,                  .;l,.....;:lONMMMMNl.         .':;d0:  cNMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMK;                   .,dxdxk0NWWMMMMMMMXx:.        .;;o0:  :XMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMk.        ...       .  .:ONMMMMMMMMMMMMMMW0l.      .;:x0, .lWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMWk'       .;,       .'.   .;o0NMMMMMMMMMMMMMWO,    .,:l0d. 'OMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMK:.     'kx,....':dc.      .,:lxKNXNMMMMMMMWO'   .;cOk' .dWMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMX:     cNMNK0kooddddo:..      .c:',oKMMMWkk0;  .;cOO, .lNMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMMk. .  'dXMMM0c;:::dNWKx:.    ..    ;KMWk:kd...;oOk, .oNMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMMNOkkkkkkXWMMNK0000KNMMMWKxlcc,. ..;dXMMKKN0kkO0XW0kk0WMMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kkKNMMMMMMMMMMMMMMMMMMMMMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMNKKXKKXKKNNKKKNWNKKKNWXKKXNXKNMMMMMMMWXXWMMWNKKXXXNWMNK0KXXKXWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMkcOd''xOckXl.;0WK:.:KWk'.dN0oOMMMMMMMO,;0MMW0;.lKd,cKXc.:0XxdXMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMKKMx..kMKKNl ,KMX: :XMO..dK0KNMMMMMMNk, :XMMK, lWk..kNc :K00XWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMx..kMMMNl ,0WK; :XMO..oxdXMMMMMMN0Kx..lNMK, cKxlkNNc ;koOWWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMx..kMMMNl ,KMX: :XMO..xWN00WMMMN0KNNd..xWK, lNWMMMNc :XNKOKMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMNk::kNMMXd;lKWXo;oXWO::xXKdkWMMW0xXWMKl;lK0c;dXWMMMXo;oKXkdKMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMWWWWWWMMWWWWWMWWWWWWWWWWWWWWMMMMWWWMMWWWWWWWWWWWMMMWWWWWWWWMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMWWWWWWWWWWWMWWWWWWWMWWWWWMMMMMMMMWWWWWWWWWWWWWWWMMMMMWNNNWMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMOco0x:;lOOllKNkc;ckNWKo:;c0MMMMMXd;;oKWNkc;ckKKxlOMW0lcxKKOdOWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMxc0Mx. '0WkcOMk. .OMMNx;. ;KMMWXO,  :NMMk. .OMWXdkMK; .xWMNdxWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMXXMMx. '0MWKXMk. .OMMX0O:  :XWKkOc. cNMMk. .OXk0NNMXl. .ckXNNWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMMx. '0MMMMMk. .OMMX0X0, .cO0XXl  cNMMk. .xx;kMMMMNkc'..'lKWMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMMx. '0MMMMMk. .OMMX0XWk' .oNMNl  :NMMk. .OW0KNKNX0WWXx,. ;KMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMMx. '0MMMMMk. .kMMKkKMWx.,KMMNc  :XMMk. .OMMNolXOlkWMMk. ;KMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMWXxcclOXWMMNklclONW0xONMNk0MWNKdccdKWNklclOXKklxNKxkKK0dldKMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMO..kMMMMMMMMMMMM
// MMMMMMMMMMMWo.'oddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddc..kMMMMMMMMMMMM
// MMMMMMMMMMMWo.                                                                        .kMMMMMMMMMMMM
// 
// The Ape Times, your daily shitcoin newspaper!
// 
// https://theapetimes.today
// https://t.me/TheApeTimes
// https://twitter.com/TheApeTimes

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

// pragma solidity ^0.8.0;

// import "./IERC20.sol";

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

// pragma solidity ^0.8.0;

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(from != address(0));
        require(to != address(0));

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount);
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _balances[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
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
            require(currentAllowance >= amount);
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract TheApeTimes is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public liquidityWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 private buyMarketingFee;
    uint256 private buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 private sellMarketingFee;
    uint256 private sellLiquidityFee;

    uint256 private tokensForMarketing;
    uint256 private tokensForLiquidity;
    uint256 private previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    // BEGIN STORY

    enum StoryType {
        Cover,
        Column,
        Ad
    }

    struct StoryInfo {
        uint256 id;
        string title;
        string subTitle;
        string body;
        StoryType storyType;
        string imageUrl;
        uint256 publicationDate;
        uint256 price;
        address owner;
    }

    uint256 public constant MIN_STORY_PRICE = 10 ether; // base price for each story

    uint256 internal maxColumnStories = 5;

    uint256 internal maxAdStories = 4;

    mapping (uint256 => StoryInfo) public stories;

    uint256 public totalStories;

    uint256 public lastCoverStory;

    uint256[] public lastColumnStories;

    uint256[] public lastAdStories;

    event StoryPosted(
        uint256 id,
        string title,
        string subTitle,
        string body,
        StoryType storyType,
        string imageUrl,
        uint256 publicationDate,
        uint256 price,
        address owner
    );

    // END POST    

    constructor() payable ERC20("TheApeTimes", "TIMES") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 10_000_000 ether;

        maxTransactionAmount = (totalSupply * 10) / 1000;
        maxWallet = (totalSupply * 10) / 1000;
        swapTokensAtAmount = (totalSupply * 1) / 1000;

        buyMarketingFee = 15;
        buyLiquidityFee = 0;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;

        sellMarketingFee = 30;
        sellLiquidityFee = 0;
        sellTotalFees =
            sellMarketingFee +
            sellLiquidityFee;

        previousFee = sellTotalFees;

        marketingWallet = _msgSender();
        liquidityWallet = _msgSender();

        excludeFromFees(_msgSender(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(liquidityWallet, true);

        excludeFromMaxTransaction(_msgSender(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(liquidityWallet, true);

        _mint(msg.sender, (totalSupply * 100) / 100);
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function createPair() external onlyOwner {
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
    }

    function openTrading() external onlyOwner {
        require(!tradingActive);
        tradingActive = true;
        swapEnabled = true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(newAmount >= (totalSupply() * 1) / 100000);
        require(newAmount <= (totalSupply() * 5) / 1000);
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxWalletAndTxnAmount(
        uint256 newTxnNum,
        uint256 newMaxWalletNum
    ) external onlyOwner {
        require(newTxnNum >= ((totalSupply() * 5) / 1000));
        require(newMaxWalletNum >= ((totalSupply() * 5) / 1000));
        maxWallet = newMaxWalletNum;
        maxTransactionAmount = newTxnNum;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;
        require(buyTotalFees <= 15);
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;
        previousFee = sellTotalFees;
        require(sellTotalFees <= 30);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
        require(IERC20(tkn).balanceOf(address(this)) > 0);
        uint256 amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0));
        require(to != address(0));

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != deadAddress &&
            !swapping
        ) {
            if (!tradingActive) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to]);
            }

            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(amount <= maxTransactionAmount);
                require(amount + balanceOf(to) <= maxWallet);
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
                require(amount <= maxTransactionAmount);
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(amount + balanceOf(to) <= maxWallet);
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount * buyTotalFees / 100;
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
        sellTotalFees = previousFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;

        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    // Newspaper logic

    function postStory(string calldata _title, string calldata _body, string calldata _subTitle, StoryType _storyType, string calldata _imageUrl) 
    external 
    {
        uint256 newStoryId = ++totalStories;

        StoryInfo memory oldStory;
        if (_storyType == StoryType.Cover) {
            oldStory = stories[lastCoverStory];
            lastCoverStory = newStoryId;
        } else if (_storyType == StoryType.Column) {
            if (lastColumnStories.length > 0) {
                if (lastColumnStories.length == maxColumnStories) {
                    oldStory = stories[lastColumnStories[0]];
                    _shiftLeft(lastColumnStories);
                }
            }
            lastColumnStories.push(newStoryId);
        } else if (_storyType == StoryType.Ad) {
            if (lastAdStories.length > 0) {
                if (lastAdStories.length == maxAdStories) {
                    oldStory = stories[lastAdStories[0]];
                    _shiftLeft(lastAdStories);
                }
            }
            lastAdStories.push(newStoryId);
        }

        uint256 storyPrice = MIN_STORY_PRICE;
        if (oldStory.price > 0) {
            storyPrice = oldStory.price;
            if (oldStory.publicationDate < block.timestamp + 1 weeks) {
                storyPrice *= 2;
            }
        }

        super._burn(msg.sender, storyPrice);
        
        StoryInfo memory newStory = StoryInfo({
            id: totalStories,
            title: _title,
            body: _body,
            subTitle: _subTitle,
            storyType: _storyType,
            imageUrl: _imageUrl,
            publicationDate: block.timestamp,
            price: storyPrice,
            owner: msg.sender
        });
        stories[newStory.id] = newStory;

        emit StoryPosted(newStory.id, newStory.title, newStory.body, newStory.subTitle, 
            newStory.storyType, newStory.imageUrl, newStory.publicationDate, newStory.price, newStory.owner);
    }

    function setMaxColumnStories(uint256 _maxColumnStories) external onlyOwner {
        maxColumnStories = _maxColumnStories;
    }

    function setMaxAdStories(uint256 _maxAdStories) external onlyOwner {
        maxAdStories = _maxAdStories;
    }

    function getCoverStory() external view returns(StoryInfo memory) {
        return stories[lastCoverStory];
    }

    function getColumnStories() external view returns(StoryInfo[] memory) {
        StoryInfo[] memory columnStories = new StoryInfo[](lastColumnStories.length);
        for (uint256 i = 0; i < lastColumnStories.length; i++) {
            columnStories[i] = stories[lastColumnStories[i]];
        }
        return columnStories;
    }

    function getAdStories() external view returns(StoryInfo[] memory) {
        StoryInfo[] memory adStories = new StoryInfo[](lastAdStories.length);
        for (uint256 i = 0; i < lastAdStories.length; i++) {
            adStories[i] = stories[lastAdStories[i]];
        }
        return adStories;
    }

    function _shiftLeft(uint256[] storage arr) internal {
        for (uint256 i = 0; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }
}