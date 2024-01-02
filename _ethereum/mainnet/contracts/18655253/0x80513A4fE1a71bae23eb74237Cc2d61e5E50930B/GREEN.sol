/**

🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢  LINKS  🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢

Telegram:  https://t.me/GreenERC20

Website:   https://www.greengreengreen.green

Docs:      https://docs.greengreengreen.green

Twitter:   https://twitter.greengreengreen.green

🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢  BASICS  🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢

$GREEN has a max supply of 100,000,000 tokens.

With each buy of $100 or more, a new 🟢 emoji is added to the token name and website background.

50% of taxes are reflected to token holders and paid out in ETH. The other 50% goes to marketing.

🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢  BUY TAX  🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢

$GREEN has a maximum buy tax of 7%.

The buy tax starts at 7% and drops by 1%, until 0%, for every 15 seconds that pass without a new buy.

🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢  SELL TAX  🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢

$GREEN has a maxmimum sell tax of 7%.

The sell tax starts at 0% and rises by 1%, up to 7%, for every sell within 30 seconds of the previous sell.

🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢  REFLECTIONS  🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢

Reflections must be claimed on the $GREEN dapp or by calling the claimDividends() function on the $GREEN token contract.

Wallets that fail to claim reflections before selling lose them, and they are automatically redistribtued to all remaining holders.

🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract GREEN is Context, IERC20, Ownable {
    string public constant Perfection = unicode"🟢";

    string private _name = unicode"🟢";
    string private constant _symbol = "GREEN";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromDividend;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address payable private _developerWallet = payable(msg.sender);
    address payable private _marketingWallet = payable(msg.sender);

    bool private dividends = true;
    uint256 public dividendShares = 1;
    uint256 public dividendPerToken;
    uint256 public dividendBalanceTotal;
    uint256 public dividendClaimedTotal;
    mapping(address => uint256) dividendBalance;
    mapping(address => uint256) dividendCredited;
    mapping(address => uint256) dividendClaimed;

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public constant uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable GREEN;
    IWETH public constant wethContract = IWETH(WETH);
    IERC20 public constant weth = IERC20(WETH);
    address public immutable uniswapV2Pair;
    AggregatorV3Interface public constant chainlinkFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    bool private tradingOpen;
    bool private inAtomicSwap;
    bool private inContractSwap;

    uint256 public maxSwap = 2000000 * 10**9;
    uint256 public maxWallet = 2000000 * 10**9;
    uint256 private constant _triggerSwap = 10**9;

    uint256 public lastPoolBalance = 1 ether;

    event Deposit(address indexed from, uint256 value);
    event Claim(address indexed to, uint256 value);

    uint256 public constant BUY_COOLDOWN = 15;
    uint256 public constant SELL_COOLDOWN = 30;
    uint256 public constant BUY_TAX_MAX = 7;
    uint256 public constant SELL_TAX_MAX = 7;
    uint256 public constant BUY_TAX_DEFAULT = 7;
    uint256 public constant SELL_TAX_DEFAULT = 0;

    uint256 private _lastBuy = block.timestamp;
    uint256 private _lastSell;
    uint256 private _sellStreak;

    uint256 private _taxFeeOnBuy = BUY_TAX_DEFAULT;
    uint256 private _taxFeeOnSell = SELL_TAX_DEFAULT;
    uint256 private _taxFee = BUY_TAX_DEFAULT;

    uint256 public constant BUY_EMOJI_TRIGGER = 100;

    modifier lockAtomicSwap {
        inAtomicSwap = true;
        _;
        inAtomicSwap = false;
    }

    constructor() {
        GREEN = address(this);
        uniswapV2Pair = uniswapV2Factory.createPair(GREEN, WETH);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[GREEN] = true;
        _isExcludedFromFee[_developerWallet] = true;
        _isExcludedFromFee[_marketingWallet] = true;

        _isExcludedFromDividend[owner()] = true;
        _isExcludedFromDividend[GREEN] = true;
        _isExcludedFromDividend[address(uniswapV2Router)] = true;
        _isExcludedFromDividend[uniswapV2Pair] = true;
        _isExcludedFromDividend[address(0x0)] = true;
        _isExcludedFromDividend[address(0xdead)] = true;

        _approve(GREEN, address(uniswapV2Router), MAX);
        _approve(owner(), address(uniswapV2Router), MAX);

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

    function getMeaningOfLife() external pure returns (string memory) {
        return Perfection;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_rOwned[account]);
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
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function _removeTax() private returns (uint256) {
        if (_taxFee == 0) {
            return 0;
        }

        uint256 _taxFeePrevious = _taxFee;
        _taxFee = 0;
        return _taxFeePrevious;
    }

    function _restoreTax(uint256 _taxFeePrevious) private {
        _taxFee = _taxFeePrevious;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "TOKEN: Transfer amount must exceed zero");

        if (from != owner() && to != owner() && from != GREEN && to != GREEN) {
            if (!tradingOpen) {
                require(from == GREEN, "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxSwap, "TOKEN: Max Transaction Limit");

            if (to != uniswapV2Pair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(GREEN);
            bool canSwap = contractTokenBalance >= _triggerSwap;

            if (contractTokenBalance >= maxSwap) {
                contractTokenBalance = maxSwap;
            }

            if (canSwap && !inAtomicSwap && from != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                inContractSwap = true;
                swapTokensForEth(contractTokenBalance);
                inContractSwap = false;
                if (GREEN.balance > 0) {
                    sendETHToFee(GREEN.balance / 2);
                    _depositDividends(GREEN, GREEN.balance);
                }
            }
        }

        bool takeFee = true;

        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = getBuyTax();
                _taxFeeOnBuy = _taxFee;
                uint256 _poolBalance = getPoolBalance();
                if (_poolBalance > lastPoolBalance) {
                    uint256 _ETHAmount = _poolBalance - lastPoolBalance;
                    uint256 _USDAmount = getBuyValue(_ETHAmount);
                    if (_USDAmount >= BUY_EMOJI_TRIGGER) {
                        _addEmoji();
                    }
                }
                _lastBuy = block.timestamp;
            }
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _updateSellStreak();
                _taxFee = getSellTax();
                _taxFeeOnSell = _taxFee;
                _lastSell = block.timestamp;
            }
        }

        lastPoolBalance = getPoolBalance();

        _tokenTransfer(from, to, amount, takeFee);
    }

    function getBuyTax() public view returns (uint256) {
        uint256 _difference = block.timestamp - _lastBuy;
        uint256 _epochs = _difference / BUY_COOLDOWN;
        return BUY_TAX_MAX - (_epochs > BUY_TAX_MAX ? BUY_TAX_MAX : _epochs);
    }

    function getSellTax() public view returns (uint256) {
        return _sellStreak > SELL_TAX_MAX ? SELL_TAX_MAX : _sellStreak;
    }

    function _updateSellStreak() private {
        uint256 _difference = block.timestamp - _lastSell;
        if (SELL_COOLDOWN >= _difference) {
            _sellStreak++;
        } else {
            _sellStreak = 0;
        }
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 answer,,,) = chainlinkFeed.latestRoundData();
        return uint256(answer / 1e8);
    }

    function getBuyValue(uint256 _ETHAmount) public view returns (uint256) {
        return _ETHAmount * getETHPrice() / 1e18;
    }

    function getPoolBalance() public view returns (uint256) {
        return weth.balanceOf(uniswapV2Pair);
    }

    function getMarketCap() external view returns (uint256) {
        if (balanceOf(uniswapV2Pair) > 0) {
            return (((getPoolBalance() * getETHPrice()) / 1e18) * (totalSupply() / balanceOf(uniswapV2Pair))) * 2;
        }

        return 0;
    }

    function _addEmoji() private {
        _name = string(abi.encodePacked(_name, unicode"🟢"));
    }

    function swapTokensForEth(uint256 _tokenAmount) private lockAtomicSwap {
        address[] memory path = new address[](2);
        path[0] = GREEN;
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount, 0, path, GREEN, block.timestamp + 3600);
    }

    function sendETHToFee(uint256 _ETHAmount) private {
        payable(_marketingWallet).call{value: _ETHAmount}("");
    }

    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function removeLimits() external onlyOwner {
        maxSwap = _tTotal;
        maxWallet = _tTotal;
    }

    function setDividends(bool _dividends) external onlyOwner {
        dividends = _dividends;
    }

    function swapTokensForEthManual(uint256 _contractTokenBalance) external {
        require(_msgSender() == _developerWallet || _msgSender() == _marketingWallet);
        swapTokensForEth(_contractTokenBalance);
    }

    function sendETHToFeeManual(uint256 _contractETHBalance) external {
        require(_msgSender() == _developerWallet || _msgSender() == _marketingWallet);
        uint256 _wethRemainder = weth.balanceOf(GREEN);
        if (_wethRemainder > 0) {
            wethContract.withdraw(_wethRemainder);
        }
        sendETHToFee(_contractETHBalance + _wethRemainder);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        return (!inContractSwap && inAtomicSwap) ? totalSupply() * 1e4 : rAmount / _getRate();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            uint256 _taxFeePrevious = _removeTax();
            _transferStandard(sender, recipient, amount);
            _restoreTax(_taxFeePrevious);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        _refreshDividends(sender);
        _refreshDividends(recipient);
        if (!inAtomicSwap || inContractSwap) {
            uint256 _senderBalanceBefore = balanceOf(sender);
            uint256 _recipientBalanceBefore = balanceOf(recipient);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[GREEN] = _rOwned[GREEN] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            if (dividends) {
                if (_isExcludedFromDividend[sender] && !_isExcludedFromDividend[recipient]) {
                    dividendShares = dividendShares + (balanceOf(recipient) - _recipientBalanceBefore);
                }
                if (!_isExcludedFromDividend[sender] && _isExcludedFromDividend[recipient]) {
                    uint256 _difference = (_senderBalanceBefore - balanceOf(sender));
                    dividendShares = dividendShares > _difference ? dividendShares - _difference : 1;
                }
            }
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
        if (dividends) {
            if (dividendBalance[sender] > 0 && balanceOf(sender) == 0) {
                _claimDividends(sender, false);
            }
            if (dividendBalance[recipient] > 0 && balanceOf(recipient) == 0) {
                _claimDividends(recipient, false);
            }
        }
    }

    function getDividendPerToken() external view returns (uint256) {
        return dividendPerToken;
    }

    function getDividendsTotal() external view returns (uint256) {
        return dividendBalanceTotal;
    }

    function getClaimedTotal() external view returns (uint256) {
        return dividendClaimedTotal;
    }

    function getDividends(address account) public view returns (uint256) {
        return dividendBalance[account] + ((balanceOf(account) * (dividendPerToken - dividendCredited[account])) / 1e27);
    }

    function getClaimed(address account) external view returns (uint256) {
        return dividendClaimed[account];
    }

    function getDividendBalance(address account) external view returns (uint256) {
        return dividendBalance[account];
    }

    function getDividendShares() external view returns (uint256) {
        return dividendShares;
    }

    function _refreshDividends(address account) private {
        if (!dividends) return;
        if (!_isExcludedFromDividend[account]) {
            dividendBalance[account] = getDividends(account);
            dividendCredited[account] = dividendPerToken;
        }
    }

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(GREEN) - balanceOf(uniswapV2Pair) - balanceOf(address(uniswapV2Router)) - balanceOf(address(0x0)) - balanceOf(address(0xdead));
    }

    function _depositDividends(address _from, uint256 _ETHAmount) private {
        if (!dividends) return;
        if (_ETHAmount > 0) {
            emit Deposit(_from, _ETHAmount);
            dividendBalanceTotal = dividendBalanceTotal + _ETHAmount;
            dividendPerToken = dividendPerToken + ((_ETHAmount * 1e27) / dividendShares);
            wethContract.deposit{value: _ETHAmount}();
        }
    }

    function depositDividends() public payable {
        _depositDividends(msg.sender, msg.value);
    }

    function _claimDividends(address account, bool manual) private {
        if (!dividends) return;
        if (manual) {
            _refreshDividends(account);
        }
        uint256 _unclaimed = dividendBalance[account];
        if (_unclaimed > 0) {
            if (manual) {
                emit Claim(msg.sender, _unclaimed);
                dividendClaimedTotal = dividendClaimedTotal + _unclaimed;
                dividendClaimed[msg.sender] = dividendClaimed[msg.sender] + _unclaimed;
                wethContract.withdraw(_unclaimed);
                dividendBalance[msg.sender] = 0;
                if (balanceOf(msg.sender) == 0) {
                    dividendCredited[msg.sender] = 0;
                }
                payable(msg.sender).call{value: _unclaimed}("");
            } else {
                emit Claim(GREEN, _unclaimed);
                dividendClaimedTotal = dividendClaimedTotal + _unclaimed;
                dividendClaimed[GREEN] = dividendClaimed[GREEN] + _unclaimed;
                wethContract.withdraw(_unclaimed);
                dividendBalance[account] = 0;
                if (balanceOf(account) == 0) {
                    dividendCredited[account] = 0;
                }
                _depositDividends(GREEN, _unclaimed);
            }
        }
    }

    function claimDividends() external {
        _claimDividends(msg.sender, true);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, 0, _taxFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * redisFee / 100;
        uint256 tTeam = tAmount * taxFee / 100;
        return (tAmount - tFee - tTeam, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        return (rAmount, rAmount - rFee - (tTeam * currentRate), rFee);
    }

    function _getRate() private view returns (uint256) {
        return _rTotal / _tTotal;
    }
}