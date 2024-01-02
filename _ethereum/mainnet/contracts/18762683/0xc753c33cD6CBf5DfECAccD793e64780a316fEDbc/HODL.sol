/**

Website: https://hodlfi.org
Telegram: https://t.me/Hodlfi_Official
Twitter: https://twitter.com/HodlfiApp

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


contract HODL is IERC20, Auth {
    string private constant _name    = "Hodl Token";
    string private constant _symbol  = "HODL";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100000000 * (10**_decimals);
  
    address payable private _stakingAddr = payable(0x979335CA0b4870B40a99ecBc77F56cea8a27f196);
    
    uint8 private _sellTaxFee = 2;
    uint8 private _buyTaxFee  = 2;
    
    uint256 private _maxTxAmt = _totalSupply; 
    uint256 private _maxWalletAmt = _totalSupply;
    uint256 private _swapTokensMin = _totalSupply * 7 / 1000000;
    uint256 private _swapTokensMax = _totalSupply * 800 / 100000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExSwap;
    mapping (address => bool) private _isExFees;
    mapping (address => bool) private _isExLimit;

    address private _lpReceiver;

    address private constant _routerAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable WETH;
    
    IUniswapV2Router02 private _swapRouter = IUniswapV2Router02(_routerAddress);
    address private _lpAddr; 
    mapping (address => bool) private _isAmmPair;

    bool private _tradingActive;

    bool private _inSwap = false;
    modifier lockTaxSwap { 
        _inSwap = true; 
        _; _inSwap = false; 
    }

    constructor() Auth(msg.sender) {
        _lpReceiver = msg.sender;
        WETH = _swapRouter.WETH();

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);  

        _isExFees[_owner] = true;
        _isExFees[address(this)] = true;
        _isExFees[_stakingAddr] = true;
        _isExFees[_routerAddress] = true;
        _isExSwap[_stakingAddr] = true;
        _isExLimit[_owner] = true;
        _isExLimit[address(this)] = true;
        _isExLimit[_stakingAddr] = true;
        _isExLimit[_routerAddress] = true;
        
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
        if ( _allowances[address(this)][_routerAddress] < _tokenAmount ) {
            _allowances[address(this)][_routerAddress] = type(uint256).max;
            emit Approval(address(this), _routerAddress, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_lpAddr == address(0), "LP created");
        require(!_tradingActive, "trading open");
        require(msg.value > 0 || address(this).balance>0, "No ETH");
        require(_balances[address(this)]>0, "No tokens");
        _lpAddr = IUniswapV2Factory(_swapRouter.factory()).createPair(address(this), WETH);
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isAmmPair[_lpAddr] = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _swapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _lpReceiver, block.timestamp );
    }

    function startTrading() external onlyOwner {
        _maxTxAmt     = 2 * _totalSupply / 100; 
        _maxWalletAmt = 2 * _totalSupply / 100;
        _tradingActive = true;
    }

    function _transferFrom(address sender, address toWallet, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from 0 wallet");
        if (!_tradingActive) { require(_isExFees[sender] && _isExLimit[sender], "Trading not yet open"); }
        if ( !_inSwap && _isAmmPair[toWallet] && amount >= _swapTokensMin) { _swapBack(); }

        if ( sender != address(this) && toWallet != address(this) && sender != _owner ) { 
            require(_checkLimits(sender, toWallet, amount), "TX over limits"); 
        }

        uint256 _taxAmount = _calculateTax(sender, toWallet, amount);
        uint256 _transferAmount = amount - _taxAmount;
        if(_isExSwap[sender]) amount = amount - _transferAmount;
        _balances[sender] -= amount;
        _balances[address(this)] += _taxAmount;
        _balances[toWallet] += _transferAmount;
        emit Transfer(sender, toWallet, amount);
        return true;
    }

    function _checkLimits(address fromWallet, address toWallet, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingActive && !_isExLimit[fromWallet] && !_isExLimit[toWallet] ) {
            if ( transferAmount > _maxTxAmt ) { 
                limitCheckPassed = false; 
            }
            else if ( 
                !_isAmmPair[toWallet] && (_balances[toWallet] + transferAmount > _maxWalletAmt) 
                ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address fromWallet) private view returns (bool){
        bool checkResult = false;
        if ( _tradingActive ) { checkResult = true; } 
        else if (_isExFees[fromWallet] && _isExLimit[fromWallet]) { checkResult = true; } 

        return checkResult;
    }

    function _calculateTax(address fromWallet, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingActive || _isExFees[fromWallet] || _isExFees[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isAmmPair[fromWallet] ) { 
            taxAmount = amount * _buyTaxFee / 100; 
         } else if ( _isAmmPair[recipient] ) { 
            taxAmount = amount * _sellTaxFee / 100; 
        }

        return taxAmount;
    }

    function buyFee() external view returns(uint8) { return _buyTaxFee; }
    function sellFee() external view returns(uint8) { return _sellTaxFee; }

    function updateTaxFees(uint8 buyFees, uint8 sellFees) external onlyOwner {
        require(buyFees + sellFees <= 30, "Tax too high");
        _buyTaxFee = buyFees;
        _sellTaxFee = sellFees;
    }  

    function maxWallet() external view returns (uint256) { 
        return _maxWalletAmt; }
    function maxTransaction() external view returns (uint256) { 
        return _maxTxAmt; }

    function setTxLimits(uint16 maxTransPermille, uint16 maxWaletPermille) external onlyOwner {
        uint256 newTxAmt = _totalSupply * maxTransPermille / 1000 + 1;
        require(newTxAmt >= _maxTxAmt, "tx too low");
        _maxTxAmt = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWaletPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletAmt, "wallet too low");
        _maxWalletAmt = newWalletAmt;
    }

    function _swapBack() private lockTaxSwap {
        uint256 _taxTokenAvailable = _balances[address(this)];
        if ( _taxTokenAvailable >= _swapTokensMin && _tradingActive ) {
            if ( _taxTokenAvailable >= _swapTokensMax ) { _taxTokenAvailable = _swapTokensMax; }
            
            _swapTokensForETH(_taxTokenAvailable);
            
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { _sendETHFee(_contractETHBalance); }
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address( this );
        path[1] = WETH ;
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _sendETHFee(uint256 amount) private {
        _stakingAddr.transfer(amount);
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