/*

Introduction to Molie Messenger ($MOLIE)
Molie Messenger is a cutting-edge messaging platform designed to revolutionize the way people communicate and manage digital assets. With a focus on privacy, security, and seamless integration of cryptocurrencies, Molie Messenger aims to provide users with a secure and convenient messaging experience.

Why?
Molie Messenger is crafted to revolutionize communication by offering a secure, user-centric messaging platform that prioritizes privacy and data security in the modern digital era.

Mission
Our mission at Molie Messenger is to redefine the way people communicate by providing a secure, private, and user-centric messaging platform that empowers individuals to connect and share in a trusted environment.

How?
We achieve this by integrating cutting-edge encryption technologies, user-centric features, and a seamless user experience to ensure that privacy and security are at the core of every interaction on the Molie Messenger platform.


Join Us:
https://t.me/MoliePortal
https://twitter.com/MolieEthereum
https://moliemessenger.com/

*/

pragma solidity 0.8.21;
// SPDX-License-Identifier: MIT

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

contract MOLIE is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    address payable private _marketingWallet;

    string private constant _name =    unicode"Messenger";
    string private constant _symbol =  unicode"MOLIE";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 10 * 1e9 * 10**_decimals;
    uint256 public _BuyMarketingFee=   10;
    uint256 public _SellMarketingFee=  45;
    uint256 public _maxTxAmount =      _tTotal * 2 / 100;
    uint256 public _maxWalletSize =    _tTotal * 2 / 100;
    uint256 public _feeSwapThreshold=  _tTotal * 5 / 10000;
    uint256 public _maxFeeSwap=        _tTotal * 1 / 100;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _marketingWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: Can't approve from the zero address");
        require(spender != address(0), "ERC20: Can't approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: Can't transfer from the zero address");
        require(to != address(0), "ERC20: Can't transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 feeAmount = 0;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                require(amount < _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount < _maxWalletSize, "Exceeds the _maxWalletSize.");
            }

            if(to == uniswapV2Pair && from != address(this)){
                feeAmount = amount * _SellMarketingFee / 100;
            }
            if(from == uniswapV2Pair && to != address(this)){
                feeAmount = amount * _BuyMarketingFee / 100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_feeSwapThreshold) {
                uint256 amountToSwap = (amount < contractTokenBalance && amount < _maxFeeSwap) ? amount : (contractTokenBalance < _maxFeeSwap) ? contractTokenBalance : _maxFeeSwap;
                swapTokensForEth(amountToSwap);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(feeAmount>0){
          _balances[address(this)] += feeAmount;
          emit Transfer(from, address(this),feeAmount);
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + (amount - feeAmount);
        emit Transfer(from, to, amount - feeAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
        if(!tradingOpen){return;}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"Trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function swapManual() external onlyOwner {
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function updateFee(uint256 BuyMarketingFee, uint256 SellMarketingFee) external onlyOwner {
        _BuyMarketingFee = BuyMarketingFee;
        _SellMarketingFee = SellMarketingFee;
    }

    receive() external payable {}
  
}