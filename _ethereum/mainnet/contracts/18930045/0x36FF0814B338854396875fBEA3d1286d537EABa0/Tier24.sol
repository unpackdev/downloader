//SPDX-License-Identifier: Unlicensed

/**
    https://twitter.com/elonmusk/status/1742681946314936336
    Completed Tier 24 in Diablo's Abattoir of Zir.
    But, as the video shows, I had less than a minute left, so definitely need to increase damage significantly to clear Tier 25, where monsters have ~3X health.
    Full glass cannon is the only option!
    
    ████████╗██████╗░░░██╗██╗
    ╚══██╔══╝╚════██╗░██╔╝██║
    ░░░██║░░░░░███╔═╝██╔╝░██║
    ░░░██║░░░██╔══╝░░███████║
    ░░░██║░░░███████╗╚════██║
    ░░░╚═╝░░░╚══════╝░░░░░╚═╝
**/

pragma solidity ^0.8.23;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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

contract Tier24 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => bool) private isExcludedFromFees;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10 ** 9;
    uint256 private _swapTokensAtAmount = _tTotal / 1000;
    uint256 private _maxTaxSwap = _tTotal / 100;
    bool private inSwap;
    bool private swapEnabled = true;
    uint256  _maxWalletAmt = _tTotal * 2 / 100;
    bool private tradingStarted;
    string private constant _name = unicode"Abattoir of Zir";
    string private constant _symbol = unicode"TIER24";
    address payable marketingWallet;
    address private uniswapV2Pair;
    uint256 public _buyFee=15;
    uint256 public _sellFee=15;
    IUniswapV2Router02 _uniswapV2Router;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        marketingWallet = payable(_msgSender());
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        isExcludedFromFees[address(this)] = true;
        _balances[msg.sender] = _tTotal;
        isExcludedFromFees[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 taxAmount=0;
        if (!isExcludedFromFees[from] && !isExcludedFromFees[to] && from != owner()) {
            require(tradingStarted, "Trade not enabled yet!");

            taxAmount = amount.mul(_buyFee).div(100);

            if (to != uniswapV2Pair && to != owner()) {
                require(balanceOf(to) + amount <= _maxWalletAmt, "Max wallet ");
            }

            if(to == uniswapV2Pair && to != owner()){
                taxAmount = amount * _sellFee / 100;
            }

            if (from == uniswapV2Pair && to != owner()) {
                require(balanceOf(to) + amount <= _maxWalletAmt, "Max wallet ");
            }

            uint256 contractBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractBalance>_swapTokensAtAmount) {
                swapTokensForEth(min(amount,min(contractBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                     marketingWallet.transfer(address(this).balance);
                }
            }
        }

        if(taxAmount > 0){
          _balances[address(this)] = _balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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

    function startTrading() external onlyOwner {
        tradingStarted = true;
    }

    function setSwapEnabled(bool status) external onlyOwner {
        swapEnabled = status;
    }

    function _setSwapTokensAtAmount(uint amount) external onlyOwner {
        _swapTokensAtAmount = amount;
    }

    function setMaxWallet(uint amount) external onlyOwner {
        require(amount >= _tTotal / 500, "Max wallet size can't be lower 0.2%!");
        _maxWalletAmt = amount;
    }

    function removeLimits() external onlyOwner{
        _maxWalletAmt = _tTotal;
    }

    function _updateFees(uint buyFees, uint sellFees) external onlyOwner {
        _buyFee = buyFees;
        _sellFee = sellFees;
        require(_buyFee <= 35 && sellFees <= 35,"Maximum 35% allowed as fees.");
    }

    function excludeFromFees(address account, bool status) external onlyOwner {
        isExcludedFromFees[account] = status;
    }

    receive() external payable {}
}