// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;





interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)



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


contract SHIBA is IERC20, Auth {
    using SafeMath for uint256;

    address private constant DEAD = address(0xdead);
    address private constant ZERO = address(0);
    address private devAddress = address(0xcECD9E887C94B33211d03835B056D5C181f55c6E);
    address private treasuryAddress = address(0xcECD9E887C94B33211d03835B056D5C181f55c6E);
    address private marketingAddress = address(0xcECD9E887C94B33211d03835B056D5C181f55c6E);
    address private liquidityAddress = address(0xcECD9E887C94B33211d03835B056D5C181f55c6E);
    /**
     * Token Assets
     * name, symbol, _decimals totalSupply
     * This will be defined when we deploy the contract.
     */
    string private _name = "Shiba";
    string private _symbol = "SHIBA";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1_000_000_000 * (10 ** _decimals);  // 1 billion

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    bool public enableTrading = false;
    uint256 public maxBalance = _totalSupply * 2 / 100; // 2%
    uint256 public maxTx = _totalSupply * 2 / 100;  // 2%
    uint256 public swapThreshold = (_totalSupply * 2) / 10000;  // 0.02%

    uint256 _buyMarketingFee = 20;
    uint256 _buyLiquidityFee = 0;
    uint256 _buyReflectionFee = 0;
    uint256 _buyTreasuryFee = 0;

    uint256 _sellMarketingFee = 40;
    uint256 _sellLiquidityFee = 0;
    uint256 _sellReflectionFee = 0;
    uint256 _sellTreasuryFee = 0;
    /**
     * Mode & Fee
     * mode1(BuyTax: treasury=2%, reflection=3%, SellTax: treasury=2%, reflection=3%)
     * mode2(BuyTax: 0, SellTax: treasury=2%, reflection=2%, luck holder reward=2%)
     * mode3(BuyTax: auto burn supply=1%, reflections to all top 150 holders=3%, 
     *       SellTax: treasury=2%, reflection=3%)
     * mode4(BuyTax: 0, SellTax: 0)
     */
    uint8 public mode = 0;  // current mode
    bool public isAutoMode = false;
    uint256 public modeStartTime = 0;
    uint256 public modePeriod = 3 hours;
    struct Fee {
        uint8 treasury;
        uint8 reflection;
        uint8 lucky;
        uint8 burn;
        uint8 total;
    }
    // mode == 0: pre fees
    // Mode 1
    Fee public mode1BuyTax = Fee({treasury: 2, reflection: 3, lucky: 0, burn: 0, total: 5});
    Fee public mode1SellTax = Fee({treasury: 2, reflection: 3, lucky: 0, burn: 0, total: 5});
    // Mode 2
    Fee public mode2BuyTax = Fee({treasury: 0, reflection: 0, lucky: 0, burn: 0, total: 0});
    Fee public mode2SellTax = Fee({treasury: 2, reflection: 2, lucky: 2, burn: 0, total: 6});
    // Mode 3
    Fee public mode3BuyTax = Fee({treasury: 0, reflection: 3, lucky: 0, burn: 1, total: 4});
    Fee public mode3SellTax = Fee({treasury: 2, reflection: 3, lucky: 0, burn: 0, total: 5});
    // Mode 4
    Fee public mode4BuyTax = Fee({treasury: 0, reflection: 0, lucky: 0, burn: 0, total: 0});
    Fee public mode4SellTax = Fee({treasury: 0, reflection: 0, lucky: 0, burn: 0, total: 0});

    Fee public buyTax;
    Fee public sellTax;

    IUniswapV2Router02 public UNISWAP_V2_ROUTER;
    address public UNISWAP_V2_PAIR;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isReflectionExempt;

    mapping(address => bool) public isHolder;
    address[] public holders;
    uint256 public totalReflectionAmount;
    uint256 public topHolderReflectionAmount;

    // events
    event UpdateMode(uint8 mode);
    event Reflection(uint256 amountAdded, uint256 totalAmountAccumulated);
    event LuckyReward(address holder, uint256 amount);
    event ChangeTradingStatus(bool status);

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () Auth(msg.sender) {
        UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        UNISWAP_V2_PAIR = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());
        _allowances[address(this)][address(UNISWAP_V2_ROUTER)] = _totalSupply;
        _allowances[address(this)][address(UNISWAP_V2_PAIR)] = _totalSupply;
        _allowances[address(this)][msg.sender] = _totalSupply;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[devAddress] = true;
        isFeeExempt[treasuryAddress] = true;
        isFeeExempt[marketingAddress] = true;
        isFeeExempt[liquidityAddress] = true;
        isFeeExempt[ZERO] = true;
        isFeeExempt[DEAD] = true;

        isReflectionExempt[address(this)] = true;
        isReflectionExempt[address(UNISWAP_V2_ROUTER)] = true;
        isReflectionExempt[UNISWAP_V2_PAIR] = true;
        isReflectionExempt[msg.sender] = true;
        // isReflectionExempt[devAddress] = true;
        // isReflectionExempt[treasuryAddress] = true;
        // isReflectionExempt[marketingAddress] = true;
        // isReflectionExempt[liquidityAddress] = true;
        isReflectionExempt[ZERO] = true;
        isReflectionExempt[DEAD] = true;

        buyTax = mode1BuyTax;
        sellTax = mode1SellTax;

        uint256 devAmount = _totalSupply * 5 / 100;
        _balances[devAddress] = devAmount;
        emit Transfer(address(0), devAddress, devAmount);
        isHolder[devAddress] = true;
        holders.push(devAddress);

        uint256 circulationAmount = _totalSupply - devAmount;
        _balances[msg.sender] = circulationAmount;
        emit Transfer(address(0), msg.sender, circulationAmount);
        isHolder[msg.sender] = true;
        holders.push(msg.sender);
    }

    receive() external payable {}
    /**
     * ERC20 Standard methods with override
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 totalBalance = _balances[account];
        if (!isReflectionExempt[account] && totalReflectionAmount > 0 && holders.length > 2) {
            totalBalance += totalBalance / holders.length;
        }
        return totalBalance;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        _checkBuySell(sender, recipient);
        _checkLimitations(recipient, amount);
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (_shouldSwapBack()) {
            _swapBack();
        }
        if (!isReflectionExempt[sender]){
            _claim(sender);
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _updateHolders(sender);
        uint256 amountReceived = _shouldTakeFee(sender, recipient) ? _takeFees(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        _updateHolders(recipient);

        if (isAutoMode) {
            autoUpdateMode();
        }

        return true;
    }

    function _basicTransfer(address sender, address receiver, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _updateHolders(sender);
        _balances[receiver] = _balances[receiver].add(amount);
        _updateHolders(receiver);
        return true;
    }

    function getRandomHolderIndex(uint256 _numToFetch, uint256 _i) internal view returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    _numToFetch,
                    _i
                )
            )
        );
        uint256 randomIndex = (randomNum % holders.length);
        return randomIndex;
    }

    function _takePreFees(address sender, uint256 amount) internal returns (uint256) {
        uint256 _marketingFee = _sellMarketingFee;
        uint256 _liquidityFee = _sellLiquidityFee;
        uint256 _reflectionFee = _sellReflectionFee;
        uint256 _treasuryFee = _sellTreasuryFee;
        if (sender == UNISWAP_V2_PAIR) {
            _marketingFee = _buyMarketingFee;
            _liquidityFee = _buyLiquidityFee;
            _reflectionFee = _buyReflectionFee;
            _treasuryFee = _buyTreasuryFee;
        }
        uint256 _marketingFeeAmount = 0;
        uint256 _liquidityFeeAmount = 0;
        uint256 _reflectionFeeAmount = 0;
        uint256 _treasuryFeeAmount = 0;
        if (_marketingFee > 0) {
            _marketingFeeAmount = amount * _marketingFee / 100;
            _balances[marketingAddress] += _marketingFeeAmount;
            emit Transfer(address(this), treasuryAddress, _treasuryFeeAmount);
        }
        if (_reflectionFee > 0) {
            _reflectionFeeAmount = amount * _reflectionFee / 100;
            totalReflectionAmount += _reflectionFeeAmount;
            emit Reflection(_reflectionFeeAmount, totalReflectionAmount);
        }
        if (_treasuryFee > 0) {
            _treasuryFeeAmount = amount * _treasuryFee / 100;
            _balances[treasuryAddress] += _treasuryFeeAmount;
            emit Transfer(address(this), treasuryAddress, _treasuryFeeAmount);
        }
        if (_liquidityFee > 0) {
            _liquidityFeeAmount = amount * _liquidityFee / 100;
            _balances[address(this)] += _liquidityFeeAmount;
        }
        uint256 _totalFeeAmount = _marketingFeeAmount + _liquidityFeeAmount + _reflectionFeeAmount + _treasuryFeeAmount;
        return amount.sub(_totalFeeAmount);
    }

    function _takeModeFees(address sender, uint256 amount) internal returns (uint256) {
        Fee memory _feeTax = sellTax;
        bool _topReflection = false;
        if (sender == UNISWAP_V2_PAIR) {
            _feeTax = buyTax;
            if (mode == 3) {
                _topReflection = true;
            }
        }
        uint256 feeAmount = amount * _feeTax.total / 100;
        if (_feeTax.treasury > 0) {
            uint256 _treasuryFeeAmount = feeAmount * _feeTax.treasury / _feeTax.total;
            _balances[treasuryAddress] += _treasuryFeeAmount;
            emit Transfer(address(this), treasuryAddress, _treasuryFeeAmount);
        }
        if (_feeTax.reflection > 0) {
            uint256 _reflectionFeeAmount = feeAmount * _feeTax.reflection / _feeTax.total;
            if (_topReflection) {
                _topHolderReflection(_reflectionFeeAmount);
            } else {
                totalReflectionAmount += _reflectionFeeAmount;
                emit Reflection(_reflectionFeeAmount, totalReflectionAmount);
            }
        }
        if (_feeTax.lucky > 0) {
            uint256 _luckyFeeAmount = feeAmount * _feeTax.lucky / _feeTax.total;
            _luckyReward(_luckyFeeAmount);
        }
        if (_feeTax.burn > 0) {
            uint256 _burnFeeAmount = feeAmount * _feeTax.burn / _feeTax.total;
            _balances[DEAD] += _burnFeeAmount;
            emit Transfer(address(this), DEAD, _burnFeeAmount);
        }

        return amount.sub(feeAmount);
    }

    function _takeFees(address sender, uint256 amount) internal returns (uint256) {
        if (mode > 0) {
            return _takeModeFees(sender, amount);
        } else {
            return _takePreFees(sender, amount);
        }
    }

    function _shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function _checkBuySell(address sender, address recipient) internal view {
        if (!enableTrading) {
            require(sender != UNISWAP_V2_PAIR && recipient != UNISWAP_V2_PAIR, "Trading is disabled!");
        }
    }

    function _checkLimitations(address recipient, uint256 amount) internal view {
        if (recipient != UNISWAP_V2_PAIR) {
            require(amount <= maxTx, "Max transaction amount is limited!");
            uint256 suggestBalance = balanceOf(recipient) + amount;
            require(suggestBalance <= maxBalance, "Max balance is limited!");
        }
    }

    function _luckyReward(uint256 amount) internal {
        uint256 randomIndex = getRandomHolderIndex(1, 1);
        address luckyHolder = holders[randomIndex];
        if (
            luckyHolder != ZERO && 
            luckyHolder != DEAD && 
            luckyHolder != address(UNISWAP_V2_ROUTER) && 
            luckyHolder != UNISWAP_V2_PAIR
        ) {
            _balances[luckyHolder] += amount;
            emit Transfer(address(this), luckyHolder, amount);
        }
    }

    function _topHolderReflection(uint256 amount) internal {
        topHolderReflectionAmount += amount;
    }
    
    function _updateHolders(address holder) internal {
        uint256 balance = balanceOf(holder);
        if (balance > 0) {
            if (!isHolder[holder]) {
                isHolder[holder] = true;
                holders.push(holder);
            }
        } else {
            if (isHolder[holder]) {
                isHolder[holder] = false;
                for(uint256 i = 0; i < holders.length - 1; i++) {
                    if (holders[i] == holder) {
                        holders[i] = holders[holders.length - 1];
                    }
                }
                holders.pop();
            }
        }
    }

    function _claim(address holder) internal {
        if (totalReflectionAmount > 0) {
            uint256 oneReflection = totalReflectionAmount / holders.length;
            totalReflectionAmount -= oneReflection;
            _balances[holder] += oneReflection;
        }
    }

    function _shouldSwapBack() internal view returns (bool) {
        return msg.sender != UNISWAP_V2_PAIR && !inSwap && balanceOf(address(this)) >= swapThreshold;
    }

    function _swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this));
        approve(address(UNISWAP_V2_ROUTER), amountToSwap);
        // swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();
        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap, 0, path, address(this), block.timestamp
        );
        uint256 amountETH = address(this).balance;
        // (bool tmpSuccess,) = payable(liquidityAddress).call{value: amountETH}("");
        payable(liquidityAddress).transfer(amountETH);
    }

    function _changeMode(uint8 mode_) internal {
        if (mode_ == 2) {
            buyTax = mode2BuyTax;
            sellTax = mode2SellTax;
        } else if (mode_ == 3) {
            buyTax = mode3BuyTax;
            sellTax = mode3SellTax;
        } else if (mode_ == 4) {
            buyTax = mode4BuyTax;
            sellTax = mode4SellTax;
        } else {
            buyTax = mode1BuyTax;
            sellTax = mode1SellTax;
        }
        mode = mode_;
        emit UpdateMode(mode_);
    }

    function autoUpdateMode() internal {
        uint8 _currentMode = mode;
        if (_currentMode == 0) {
            return;
        }
        uint256 deltaTime = block.timestamp - modeStartTime;
        if (deltaTime < modePeriod) {
            return;
        }
        _currentMode = (_currentMode + 1) % 4;
        if (_currentMode == 0) {
            _currentMode = 1;
        }
        modeStartTime = block.timestamp;
        _changeMode(_currentMode);
    }

    function manualUpdateMode(uint8 mode_) external authorized {
        require(mode_ < 5, "Undefined Mode");
        _changeMode(mode_);
    }

    function setAutoMode(bool isAuto_) external authorized {
        isAutoMode = isAuto_;
    }

    function rewardTopHolders(address[] calldata _topHolders) public authorized {
        require(topHolderReflectionAmount > 0, "Reward should be available");
        uint256 oneReward = topHolderReflectionAmount / _topHolders.length;
        topHolderReflectionAmount = 0;
        for (uint8 i = 0; i < _topHolders.length; i++) {
            _balances[_topHolders[i]] += oneReward;
            emit Transfer(address(this), _topHolders[i], oneReward);
        }
    }

    function setFeeReceivers(address treasury_) external authorized {
        treasuryAddress = treasury_;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsReflectionExempt(address holder, bool exempt) external authorized {
        isReflectionExempt[holder] = exempt;
    }

    function changeTradingStatus(bool _status) external authorized {
        enableTrading = _status;
        emit ChangeTradingStatus(_status);
    }

    function updatePreFees(
        uint256 buyMarketingFee_,
        uint256 buyLiquidityFee_,
        uint256 buyReflectionFee_,
        uint256 buyTreasuryFee_,
        uint256 sellMarketingFee_,
        uint256 sellLiquidityFee_,
        uint256 sellReflectionFee_,
        uint256 sellTreasuryFee_
    ) external authorized {
        _buyMarketingFee = buyMarketingFee_;
        _buyLiquidityFee = buyLiquidityFee_;
        _buyReflectionFee = buyReflectionFee_;
        _buyTreasuryFee = buyTreasuryFee_;

        _sellMarketingFee = sellMarketingFee_;
        _sellLiquidityFee = sellLiquidityFee_;
        _sellReflectionFee = sellReflectionFee_;
        _sellTreasuryFee = sellTreasuryFee_;
    }

    function updateSwapThreshold(uint256 _swapThreshold) external authorized {
        swapThreshold = _swapThreshold;
    }

    function manualSwapBack() external authorized {
        if (_shouldSwapBack()) {
            _swapBack();
        }
    }
}