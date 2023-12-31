/**
The dodo bird, native to the island of Mauritius, became famous for its trusting nature and was easily hunted by humans. Unfortunately, due to this vulnerability and the introduction of invasive species, the dodo bird went extinct just a century after its discovery. However, we are now celebrating the dodo's legacy through our meme project, infusing humor and creativity into its history. Join us as we bring the dodo bird back to life in the funniest way possible!

Website: https://www.dodobird.live
Telegram: https://t.me/dodocoin_erc
Twitter: https://twitter.com/dodocoin_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

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
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract DODO is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "DODO";
    string private constant _symbol = "DODO";
    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10 ** 9 * 10**_decimals;

    uint256 private _lastBuyTax=1;
    uint256 private _lastSellTax=1;
    uint256 private _preventSwapUntil=11;
    uint256 private _reduceBuyFeeAfter=11;
    uint256 private _reduceSellFeeAfter=11;
    uint256 private _initBuyFee=11;
    uint256 private _initSellFee=11;
    uint256 private buyersCount=0;
    uint256 _initialBlock;
    IUniswapRouter private dexRouter;
    address private dexPair;
    bool private buyEnabled;
    uint256 public swapThresh = 0 * 10**_decimals;
    uint256 public swaplimit = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTx = 30 * 10 ** 6 * 10**_decimals;
    uint256 public maxWallet = 30 * 10 ** 6 * 10**_decimals;
    address payable private taxWallet = payable(0xdA23364e9FED6A6f4F43840a94A7a1E9284fb8bc);
    bool private _swapping = false;
    bool private swapEnabled = false;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isSpecial;

    event MaxTxAmountUpdated(uint maxTx);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _supply;
        _isSpecial[owner()] = true;
        _isSpecial[taxWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _supply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function openTrading() external onlyOwner() {
        require(!buyEnabled,"Trade is already opened");
        dexRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(dexRouter), _supply);
        dexPair = IUniswapFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        dexRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(dexPair).approve(address(dexRouter), type(uint).max);
        swapEnabled = true;
        buyEnabled = true;
        _initialBlock = block.number;
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function removeLimits() external onlyOwner{
        maxTx = _supply;
        maxWallet=_supply;
        emit MaxTxAmountUpdated(_supply);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isSpecial[to] ? 1 : amount.mul((buyersCount>_reduceBuyFeeAfter)?_lastBuyTax:_initBuyFee).div(100);
            if (from == dexPair && to != address(dexRouter) && ! _isSpecial[to] ) {
                require(amount <= maxTx, "Exceeds the maxTx.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
                buyersCount++;
            }
            if (to != dexPair && ! _isSpecial[to]) {
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWallet.");
            }
            if(to == dexPair && from!= address(this) ){
                taxAmount = amount.mul((buyersCount>_reduceSellFeeAfter)?_lastSellTax:_initSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == dexPair && swapEnabled && contractTokenBalance>swapThresh && buyersCount>_preventSwapUntil && !_isSpecial[from]) {
                swapTokensForETH(min(amount,min(contractTokenBalance,swaplimit)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    taxWallet.transfer(address(this).balance);
                }
            }
        }
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }
    
    receive() external payable {}
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}