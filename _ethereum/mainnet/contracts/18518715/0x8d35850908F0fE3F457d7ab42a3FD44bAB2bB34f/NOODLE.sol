// SPDX-License-Identifier: MIT

/*
Worlds Fastest Dertiatives Trading Platform.

Website: https://www.noodlefi.vip
Telegram: https://t.me/noodlefi_erc
Twitter: https://twitter.com/noodle_fi
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

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMathLibs {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathLibs: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathLibs: subtraction overflow");
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
        require(c / a == b, "SafeMathLibs: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathLibs: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface UniswapFactoryInterface {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniswapRouterInterface {
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

contract NOODLE is Context, ERC20Interface, Ownable {
    using SafeMathLibs for uint256;

    uint8 private constant _decimals= 9;
    uint256 private constant _tSupply = 10 ** 9 * 10**_decimals;
    string private constant _name= "Noodle Fi";
    string private constant _symbol= "NOODLE";

    uint256 private _initialBuyTax=13;
    uint256 private _initialSellTax=13;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=13;
    uint256 private _reduceSellTaxAt=13;
    uint256 private _preventSwapBefore=7;
    uint256 private _buyers=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedForFee;

    UniswapRouterInterface private uniswapRouter;
    address private uniswapPair;
    bool private tradeActive;
    bool private inswap= false;
    bool private swapEnabled= false;

    uint256 public maxTransactionAmount= 30 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletAmount= 30 * 10 ** 6 * 10**_decimals;
    uint256 public _feeSwapThreshold= 10 ** 5 * 10**_decimals;
    uint256 public _feeSwapMax= 10 ** 7 * 10**_decimals;
    address payable private _feeAddy = payable(0x70F90D4AEDa7c85b59f4B8DeBD627ACBFC23A6Ec);

    event MaxTxAmountUpdated(uint maxTransactionAmount);
    modifier lockTheSwap {
        inswap = true;
        _;
        inswap = false;
    }

    constructor () {
        _balances[address(this)] = _tSupply;
        _isExcludedForFee[owner()] = true;
        _isExcludedForFee[_feeAddy] = true;

        emit Transfer(address(0), address(this), _tSupply);
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
        return _tSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && !_isExcludedForFee[from]) {
            taxAmount = amount.mul((_buyers > _reduceBuyTaxAt) ? _finalBuyTax  :_initialBuyTax).div(100);

            if (from == uniswapPair && to != address(uniswapRouter) && !_isExcludedForFee[to]) {
                require(amount <= maxTransactionAmount, "Exceeds the maxTransactionAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletSize.");
                _buyers++;
            }

            if (to == uniswapPair && from != address(this)) {
                taxAmount = amount.mul((_buyers>_reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inswap && to == uniswapPair && swapEnabled && contractTokenBalance > _feeSwapThreshold && _buyers > _preventSwapBefore && amount > _feeSwapThreshold) {
                swapToETH(min(amount, min(contractTokenBalance, _feeSwapMax)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendFee(address(this).balance);
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
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function openTrading() external onlyOwner() {
        require(!tradeActive, "Trading is already open");
        uniswapRouter = UniswapRouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapRouter), _tSupply);
        uniswapPair = UniswapFactoryInterface(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        ERC20Interface(uniswapPair).approve(address(uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradeActive = true;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }


    receive() external payable {}
    
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
        maxWalletAmount = maxTransactionAmount = _tSupply;
        emit MaxTxAmountUpdated(_tSupply);
    }
    
    function sendFee(uint256 amount) private {
        _feeAddy.transfer(amount);
    }
    
}