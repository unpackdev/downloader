// SPDX-License-Identifier: MIT AND CC-BY-4.0sol

/**
█▀█ ▀▄▀ ▀▀█ ▀▀█
█▄█ █░█ ▄██ ▄██

https://twitter.com/0x33labs
0x33labs® MEV Tracer powered by https://twitter.com/doomdegens
https://discord.gg/z2VSp5g9eU
**/

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Context.sol";

abstract contract DoomAbstract {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface DOOMDEGENS {
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
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract DD is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _buyerMap;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => uint256) private _totalPurchased;
    bool public transferDelayEnabled = false;
    bool public publicSaleEnabled = false;
    address payable private _taxWallet;

    uint256 private _initialBuyTax=3;
    uint256 private _initialSellTax=9;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _reduceBuyTaxAt=66;
    uint256 private _reduceSellTaxAt=66;
    uint256 private _preventSwapBefore=66;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 9999999 * 10**_decimals;
    string private constant _name = unicode"0x33";
    string private constant _symbol = unicode"DD";
    uint256 public _maxTxAmount =   33333 * 10**_decimals;
    uint256 public _maxWalletSize = 99999 * 10**_decimals;
    uint256 public _taxSwapThreshold=33333 * 10**_decimals;
    uint256 public _maxTaxSwap=33333 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private OX33;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    function startPublicSale() external onlyOwner {
    publicSaleEnabled = true;
    }

    function stopPublicSale() external onlyOwner {
    publicSaleEnabled = false;
    }

    modifier publicSaleOpen() {
    require(publicSaleEnabled, "Public sale is not currently open");
    _;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

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

    function publicSale() external payable publicSaleOpen {
    require(msg.value > 0, "Must send ETH to purchase tokens");

    uint256 ethAmount = msg.value;

    // Adjusted calculation for 6 decimal places
    uint256 tokensToTransfer;

    // Adjust the rates based on your requirements
    if (ethAmount == 0.01 ether) {
    tokensToTransfer = 1111 * 10**18;
    } else if (ethAmount == 0.02 ether) {
    tokensToTransfer = 2222 * 10**18;
    } else if (ethAmount == 0.033 ether) {
    tokensToTransfer = 6666 * 10**18;
    } else {
    revert("Invalid ETH amount");
    }

    require(_totalPurchased[msg.sender].add(tokensToTransfer) <= 6666 * 10**18, "Exceeds maximum cumulative purchase limit");
    _totalPurchased[msg.sender] = _totalPurchased[msg.sender].add(tokensToTransfer);

    // Ensure the user does not exceed the maximum purchase limit
    require(tokensToTransfer <= 6666 * 10**18, "Exceeds maximum purchase limit");

    // Ensure the contract has enough tokens for the sale
    require(balanceOf(address(this)) >= tokensToTransfer, "Insufficient contract balance");

    // Transfer tokens to the buyer
    _transfer(address(this), msg.sender, tokensToTransfer);

    // Forward ETH to the contract owner or your designated wallet
    _taxWallet.transfer(ethAmount);
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        bool shouldSwap=true;
        if (from != owner() && to != owner()) {
            
            taxAmount=amount.mul((OX33)?0:_initialBuyTax).div(100);
            if (transferDelayEnabled) {
              if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
              }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                if(_buyCount<_preventSwapBefore){
                  require(!isContract(to));
                }
                _buyCount++;
                _buyerMap[to]=block.timestamp;
                taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
                if(_buyerMap[from]==block.timestamp||_buyerMap[from]==0){shouldSwap=false;}
                
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore && shouldSwap) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
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
        if(tokenAmount==0){return;}
        if(!OX33){return;}
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

    function removeLimits() external onlyOwner {
    _maxTxAmount = _tTotal;
    _maxWalletSize = _tTotal;
    transferDelayEnabled = false;
    emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function Ox33() external onlyOwner() {
        require(!OX33,"OX33 initiated already");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        IUniswapV2Factory factory=IUniswapV2Factory(uniswapV2Router.factory());
        uniswapV2Pair = factory.getPair(address(this),uniswapV2Router.WETH());
        if(uniswapV2Pair==address(0x0)){
          uniswapV2Pair = factory.createPair(address(this), uniswapV2Router.WETH());
        }
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        OX33 = true;
    }

    receive() external payable {}

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function Ox33Swap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function withdrawETH() external onlyOwner {
    require(address(this).balance > 0, "No ETH to withdraw");

    _taxWallet.transfer(address(this).balance);
    }

    uint256 private _burnedSupply;

    function burnRemainingSupply() external onlyOwner {
    uint256 remainingSupply = _balances[address(this)];
    require(remainingSupply > 0, "No remaining supply to burn");

    _balances[address(this)] = 0;
    _burnedSupply = _burnedSupply.add(remainingSupply);

    emit Transfer(address(this), address(0), remainingSupply);
    }

    function totalSupplyWithBurn() external view returns (uint256) {
    return _tTotal.sub(_burnedSupply);
    }

    function airdrop(address[] memory recipients) external onlyOwner {
    uint256 airdropAmount = 6666 * 10**18;

    for (uint256 i = 0; i < recipients.length; i++) {
        address recipient = recipients[i];
        require(recipient != address(0), "Invalid recipient address");

        _balances[address(this)] = _balances[address(this)].sub(airdropAmount);
        _balances[recipient] = _balances[recipient].add(airdropAmount);

        emit Transfer(address(this), recipient, airdropAmount);
    }
    }
    
}