// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        // Gnosis Safe MultiSig Wallet
        _owner = address(0xd701a9BAB866610189285E1BE17D2A80A4Df29b3);
        emit OwnershipTransferred(address(0), _owner);
    }

    function renounounceOwnership() public onlyOwner {
        _owner = address(0);
        pendingOwner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        pendingOwner = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Caller != pending owner');
        address oldOwner = _owner;
        _owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, _owner);
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISacrificePointsPool {
    function sacrifice(uint256 poolId, uint256 points) external;

    function depositETH(uint256 poolId) external payable;
}

contract MAMOT is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    ISacrificePointsPool public sacrificeContract;

    // Gnosis Safe Multisig Protocol Wallet
    address payable public marketingAddress = payable(0xd701a9BAB866610189285E1BE17D2A80A4Df29b3);
    address payable public sacrificeAddress;

    address payable public deployerWallet = payable(address(this));
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 public allTimeHigh;
    uint256 public antiDumpThreshold = 40;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 55000000 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;

    string private constant _name = 'MAMOT';
    string private constant _symbol = 'MAMOT';
    uint8 private constant _decimals = 18;

    // Used in variable fee calculations
    uint256 private _tempLiquidityFee = 0;

    uint256 public _transferFee = 20;

    uint256 public _buySacrificeFee = 1;
    uint256 public _buyHolderFee = 2;
    uint256 public _buyMarketingFee = 2;
    uint256 private _buyLiquidityFee = 5;

    uint256 public _sellSacrificeFee = 0;
    uint256 public _sellHolderFee = 4;
    uint256 public _sellMarketingFee = 4;
    uint256 private _sellLiquidityFee = 8;

    bool public tradingOpen = true;
    bool public transferFeeTogle = true;

    address public tradingSetter;

    // Protocol Fees
    uint256 public _bMaxTxAmount = 100000 * 10 ** 18;
    uint256 public _sMaxTxAmount = 100000 * 10 ** 18;
    uint256 private minimumTokensBeforeSwap = 1000 * 10 ** 18;

    IUniswapV2Router01 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public sacrificeFunction = false;
    bool public antiDump = true;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapTokensForETH(uint256 amountIn, address[] path);

    constructor(address _sacrificeContract) {
        require(_sacrificeContract != address(0), 'Address should not be 0');

        sacrificeAddress = payable(_sacrificeContract);

        // Gnosis safe Multisig Wallets
        _rOwned[owner()] = _rTotal;

        sacrificeContract = ISacrificePointsPool(_sacrificeContract);
        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(routerAddress);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        tradingSetter = owner();

        // Protocol Multisig Wallets
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[deployerWallet] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[sacrificeAddress] = true;
        _isExcludedFromFee[deadAddress] = true;

        // Gnosis safe Multisig Token Distribution wallets
        _isExcludedFromFee[address(0xEb3dE025B9d6EcC7C48b57876a669175730bFD9F)] = true;
        _isExcludedFromFee[address(0x5b8C5bcD639f76654CeE8EC1BAe8235e3A5D40df)] = true;
        _isExcludedFromFee[address(0x1a0a096d2c8a8dc1045CE1Edd35Dc88BC9f5831a)] = true;
        _isExcludedFromFee[address(0xe657E3F9BCDF9a28BD9B09dbDAf29CDa6f00b398)] = true;

        // Gnosis safe Multisig Dev and Marketing wallet
        _isExcludedFromFee[address(0x0F2589065324d88c52165937c59BfF4741a4d778)] = true;

        // Gnosis safe Multisig Owner Wallets
        _isExcludedFromFee[address(0xd701a9BAB866610189285E1BE17D2A80A4Df29b3)] = true;
        _isExcludedFromFee[address(0x875294c47fDF79A093A16F0FeBaE590655449833)] = true;
        _isExcludedFromFee[address(0x3F062683FaeA9518614b118CcafEcaF36c44B810)] = true;
        _isExcludedFromFee[address(0x0F68D04AC475A196B04Df236c9E3d79c8947dD01)] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    /* PUBLIC FUNCTION STARTS */

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenAfterFee(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function tokenAfterFee(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, 'Amount must be less than total reflections');
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /* PUBLIC FUNCTION ENDS */

    /* PRIVATE FUNCTION STARTS */

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setAntiDumpThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 0 && _threshold < 100, 'Threashold must be greater than 0 and less than 100%');
        antiDumpThreshold = _threshold;
    }

    function checkAntiDump(address from, address to) internal {
        if (from == uniswapV2Pair) {
            uint256 currentPrice = getCurrentPrice();
            if (allTimeHigh == 0) {
                allTimeHigh = currentPrice;
            } else if (currentPrice > allTimeHigh) {
                allTimeHigh = currentPrice;
            }
        }
        if (to == uniswapV2Pair) {
            uint256 currentPrice = getCurrentPrice();
            if (allTimeHigh == 0) {
                allTimeHigh = currentPrice;
            } else {
                if (currentPrice < (allTimeHigh * (100 - antiDumpThreshold)) / 100) {
                    // Price has dropped by antiDumpThreshold or more, prevent selling
                    require(from == owner() || _isExcludedFromFee[from], 'Selling is currently restricted');
                } else if (currentPrice > allTimeHigh) {
                    allTimeHigh = currentPrice;
                }
            }
        }
    }

    function getCurrentPrice() internal view returns (uint256) {
        // Get the Uniswap router instance
        IUniswapV2Router01 router = IUniswapV2Router01(routerAddress);

        // Define the token addresses (your token and ETH)
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 amountIn = 1e18;

        // Get the amounts out (results[1] contains the amount of ETH you can get for 1 token)
        uint256[] memory results = router.getAmountsOut(amountIn, path);

        return results[1]; // The price of 1 token in terms of ETH
    }

    function tokenPrice() public view returns (uint256) {
        return getCurrentPrice();
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');
        if (tradingOpen == false) {
            require(_isExcludedFromFee[to] || _isExcludedFromFee[from], 'Trading Not Yet Started.');
        }

        if (antiDump && from != owner() && to != owner()) {
            checkAntiDump(from, to);
        }

        if (from != owner() && to != owner() && !_isExcludedFromFee[to] && !_isExcludedFromFee[from]) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _bMaxTxAmount, 'Transfer amount exceeds max buy amount.');
            }
            if (to == uniswapV2Pair && !_isExcludedFromFee[from]) {
                require(amount <= _sMaxTxAmount, 'Transfer amount exceeds the max sell amount.');
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // Sell tokens for ETH
        if (!inSwapAndLiquify && swapAndLiquifyEnabled && balanceOf(uniswapV2Pair) > 0) {
            if (to == uniswapV2Pair && overMinimumTokenBalance) {
                feeDistribution();
            }
        }

        _tempLiquidityFee = 0;
        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            _tempLiquidityFee = 0;
        } else {
            if (from != uniswapV2Pair && to != uniswapV2Pair && transferFeeTogle) {
                _tempLiquidityFee = _transferFee;
            }

            // Buy
            if (from == uniswapV2Pair) {
                _tempLiquidityFee = _buyLiquidityFee;
            }
            // Sell
            if (to == uniswapV2Pair) {
                _tempLiquidityFee = _sellLiquidityFee;
            }
        }

        _tokenTransfer(from, to, amount);
    }

    function swapTokenManual(uint256 tokenAmount) external onlyOwner {
        swapTokensForEth(tokenAmount, address(this));
    }

    function feeDistribution() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // Sell tokens for ETH
        if (overMinimumTokenBalance) {
            contractTokenBalance = minimumTokensBeforeSwap;
            uint256 _holderFee = _sellHolderFee;
            uint256 _marketingFee = _sellMarketingFee;
            uint256 _sacrificeFee = _sellSacrificeFee;

            if (_holderFee == 0) {
                _holderFee = _buyHolderFee;
            }
            if (_marketingFee == 0) {
                _marketingFee = _buyMarketingFee;
            }
            if (_sacrificeFee == 0) {
                _sacrificeFee = _buySacrificeFee;
            }

            uint256 _liquidityFee = _holderFee + _marketingFee + _sacrificeFee;

            uint256 marketingToken = 0;
            uint256 sacrificeToken = 0;
            uint256 holderToken = 0;

            if (_liquidityFee > 0) {
                marketingToken = contractTokenBalance.mul(_marketingFee).div(_liquidityFee);
                sacrificeToken = contractTokenBalance.mul(_sacrificeFee).div(_liquidityFee);
                holderToken = contractTokenBalance.sub(marketingToken).sub(sacrificeToken);
            }

            swapTokensForEth(marketingToken + holderToken, payable(address(this)));
            uint256 ethTotal = address(this).balance;
            uint256 ethTotalLiquidity = _holderFee + _marketingFee;
            uint256 marketingEth = ethTotal.mul(_marketingFee).div(ethTotalLiquidity);
            uint256 holderEth = ethTotal.sub(marketingEth);
            if (marketingEth > 0) {
                (bool success, ) = marketingAddress.call{value: marketingEth}('');
                require(success, 'Address: unable to send value, recipient may have reverted');
            }

            if (sacrificeFunction) {
                if (sacrificeToken > 0) {
                    // Approve SacrificePointsPool contract to spend tokens
                    IERC20(address(this)).approve(address(sacrificeContract), sacrificeToken);
                    // Deposit points to SacrificePointsPool
                    sacrificeContract.sacrifice(1, sacrificeToken);
                }
                if (holderEth > 0) {
                    sacrificeContract.depositETH{value: holderEth}(1);
                }
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount, address _toAddress) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _toAddress,
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(tAmount, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, tTransferAmount, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        return (tTransferAmount, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tLiquidity,
        uint256 currentRate
    ) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidity);
        return (rAmount, rTransferAmount);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[deployerWallet] = _rOwned[deployerWallet].add(rLiquidity);
        if (_isExcluded[deployerWallet]) _tOwned[deployerWallet] = _tOwned[deployerWallet].add(tLiquidity);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_tempLiquidityFee).div(10 ** 2);
    }

    // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    /* PRIVATE FUNCTION ENDS */

    /* OWNER FUNCTION STARTS */

    //Use when new router is released and pair HAS been created already.
    function setRouterAddress(address newRouter) external onlyOwner {
        require(newRouter != address(0), 'Address should not be 0');
        IUniswapV2Router01 _newPancakeRouter = IUniswapV2Router01(newRouter);
        uniswapV2Router = _newPancakeRouter;
    }

    //Use when new router is released and pair HAS been created already.
    function setPairAddress(address newPair) external onlyOwner {
        require(newPair != address(0), 'Address should not be 0');
        uniswapV2Pair = newPair;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyMaxTxAmount(uint256 bMaxTxAmount) external onlyOwner {
        require(bMaxTxAmount >= (_tTotal / 1000), 'Amount Should be greater than 0.1% of the total Supply');
        _bMaxTxAmount = bMaxTxAmount;
    }

    function setSellMaxTxAmount(uint256 sMaxTxAmount) external onlyOwner {
        require(sMaxTxAmount >= (_tTotal / 1000), 'Amount Should be greater than 0.1% of the total Supply');
        _sMaxTxAmount = sMaxTxAmount;
    }

    function setMinTokensToInitiateSwap(uint256 _minimumTokensBeforeSwap) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), 'Address should not be 0');
        marketingAddress = payable(_marketingAddress);
        _isExcludedFromFee[marketingAddress] = true;
    }

    function setSacrificeAddress(address _sacrificeContract) external onlyOwner {
        require(_sacrificeContract != address(0), 'Address should not be 0');
        sacrificeAddress = payable(_sacrificeContract);
        sacrificeContract = ISacrificePointsPool(_sacrificeContract);
        _isExcludedFromFee[sacrificeAddress] = true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeRouterVersion(address _router) external onlyOwner returns (address _pair) {
        require(_router != address(0), 'Address should not be 0');
        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(_router);

        _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        if (_pair == address(0)) {
            // Pair doesn't exist
            _pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        }
        uniswapV2Pair = _pair;

        // Set the router of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    // for stuck tokens of other types
    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        return _sent;
    }

    function setRewardMarketingDevFee(
        uint256 _sellHolderPercent,
        uint256 _sellSacrificePercent,
        uint256 _sellMarketingPercent,
        uint256 _buyHolderPercent,
        uint256 _buySacrificePercent,
        uint256 _buyMarketingPercent
    ) external onlyOwner {
        require(
            (_sellHolderPercent + _sellMarketingPercent + _sellSacrificePercent) <= 10,
            'Total Sell Percent Should be less than 10%'
        );
        require(
            (_buyHolderPercent + _buySacrificePercent + _buyMarketingPercent) < 10,
            'Total Buy Percent Should be less than 10%'
        );

        _sellSacrificeFee = _sellSacrificePercent;
        _sellMarketingFee = _sellMarketingPercent;
        _sellHolderFee = _sellHolderPercent;

        _buySacrificeFee = _buySacrificePercent;
        _buyMarketingFee = _buyMarketingPercent;
        _buyHolderFee = _buyHolderPercent;

        _buyLiquidityFee = _buySacrificePercent + _buyMarketingPercent + _buyHolderPercent;
        _sellLiquidityFee = _sellMarketingPercent + _sellSacrificePercent + _sellHolderPercent;
    }

    function setTransferFee(uint256 _transferFee_) external onlyOwner {
        require(_transferFee_ < 20, 'Transfer Fee should be less than 20%');
        _transferFee = _transferFee_;
    }

    /* Turn on or Off the Trading Option */
    function setTradingOpen(bool _status) external onlyOwner {
        require(tradingSetter == msg.sender, 'Ownership of Trade Setter Renounced');
        tradingOpen = _status;
    }

    function setSacrificeFunction(bool _status) external onlyOwner {
        sacrificeFunction = _status;
    }

    function setAntiDump(bool _status) external onlyOwner {
        antiDump = _status;
    }

    /* Renounce Trading Setter Address */
    /* Note : Once Renounced trading cant be closed */
    function renounceTradingOwner() external onlyOwner {
        require(tradingOpen == true, 'Trading Must be turned on before Renouncing Ownership');
        tradingSetter = address(0);
    }

    // Recommended : For stuck tokens (as a result of slight miscalculations/rounding errors)
    function SweepStuck(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, 'Amount should be greater than 0');
        (bool success, ) = owner().call{value: _amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /* OWNER FUNCTION ENDS */
}