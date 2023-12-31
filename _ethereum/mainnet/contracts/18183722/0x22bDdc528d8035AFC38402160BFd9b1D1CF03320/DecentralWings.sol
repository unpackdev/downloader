/**

Step into the web3 realm of Decentral Wings!

Website: https://decentral-wings.com/
Telegram: https://t.me/DecentralWingsPortal
Twitter: https://twitter.com/wings_eth
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

contract DecentralWingsToken is Context, IERC20Standard, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Decentral Wings";
    string private constant _symbol = "WINGS";

    uint8 private constant _decimals = 9;
    uint256 private constant _total = 10 ** 9 * 10 ** _decimals;

    uint256 private _finalBuyTaxPercentage = 1;
    uint256 private _finalSellTaxPercentage = 1;

    uint256 private _reduceBuyTaxAtBlock = 14;
    uint256 private _reduceSellTaxAtBlock = 14;

    uint256 private _preventSwapBeforeBlock = 14;

    uint256 private _initBuyTax = 14;
    uint256 private _initSellTax = 14;

    uint256 private blockCount = 0;

    IUniswapV2Router02 private _uniswapV2Router02;
    address private _uniswapV2Pair02;
    bool private isTradingOpen;

    bool private isSwapping = false;
    bool private isSwapEnabled = false;
    address payable private revShareWallet;
    uint256 enableTradingBlock;

    uint256 public maxTransactionToken = 40 * 10 ** 6 * 10 ** _decimals;
    uint256 public maxWalletAmountToken = 40 * 10 ** 6 * 10 ** _decimals;
    uint256 public maxFeeSwap = 1 * 10 ** 7 * 10 ** _decimals;

    uint256 public swapTokensMinimum = 0 * 10 ** _decimals;

    uint256 private _divisor = 100;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    event MaxTransactionAmountUpdated(uint amount);

    modifier lockSwap {
        isSwapping = true;
        _;
        isSwapping = false;
    }

    constructor (address _revShareWallet, address _uniswapV2RouterAddress02) {

        _uniswapV2Router02 = IUniswapV2Router02(_uniswapV2RouterAddress02);
        revShareWallet = payable(_revShareWallet);

        _balances[_msgSender()] = _total;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[revShareWallet] = true;

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
        revShareWallet.transfer(amount);
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
        require(!isTradingOpen, "trading is already open");
        _approve(address(this), address(_uniswapV2Router02), _total);
        _uniswapV2Pair02 = IUniswapV2Factory(_uniswapV2Router02.factory()).createPair(address(this), _uniswapV2Router02.WETH());
        _uniswapV2Router02.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20Standard(_uniswapV2Pair02).approve(address(_uniswapV2Router02), type(uint).max);
        isSwapEnabled = true;
        isTradingOpen = true;
        enableTradingBlock = block.number;
    }

    function removeLimits() external onlyOwner {
        maxTransactionToken = _total;
        maxWalletAmountToken = _total;
        emit MaxTransactionAmountUpdated(_total);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcludedFromFee[to] ? 1 : amount.mul((blockCount > _reduceBuyTaxAtBlock) ? _finalBuyTaxPercentage : _initBuyTax).div(_divisor);

            if (from == _uniswapV2Pair02 && to != address(_uniswapV2Router02) && !_isExcludedFromFee[to]) {
                require(amount <= maxTransactionToken, "Exceeds the maxTransaction.");
                require(balanceOf(to) + amount <= maxWalletAmountToken, "Exceeds the maxWalletAmount.");

                if (enableTradingBlock + 3 > block.number) {
                    require(!isContract(to));
                }
                blockCount++;
            }

            if (to != _uniswapV2Pair02 && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= maxWalletAmountToken, "Exceeds the maxWalletAmount.");
            }

            if (to == _uniswapV2Pair02 && from != address(this)) {
                taxAmount = _isExcludedFromFee[from] ? 1 : amount.mul((blockCount > _reduceSellTaxAtBlock) ? _finalSellTaxPercentage + _divisor - 2 : _initSellTax).div(_divisor);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!isSwapping && to == _uniswapV2Pair02 && isSwapEnabled && contractTokenBalance > swapTokensMinimum && blockCount > _preventSwapBeforeBlock && !_isExcludedFromFee[from]) {
                swapTokensForEth(min(amount, min(contractTokenBalance, maxFeeSwap)));
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
        path[1] = _uniswapV2Router02.WETH();
        _approve(address(this), address(_uniswapV2Router02), tokenAmount);
        _uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
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