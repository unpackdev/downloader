/*
 *   Tg:      https://t.me/IStandWithElonMusk
 *   Twitter: https://twitter.com/Imwithelonmusk
 *   Website: https://istandwithelonmusk.io/
 */

//SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

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

contract ISWEM is IERC20, Auth {
    string private constant _name         = "Woke Mind Virus";
    string private constant _symbol       = "istandwithelonmusk";
    uint8  private constant _decimals     = 9;
    uint256 private constant _totalSupply = 69_420_628 * (10**_decimals);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint32 private _launchTime;
    address payable private constant _walletMarketing = payable(0x875465B57Eef5Eda3cC0A4B5C89057fDcB0fa6D9);
    uint256 private constant _taxSwapMin = _totalSupply / 200000;
    uint256 private constant _taxSwapMax = _totalSupply / 1000;
    mapping (address => bool) private _excluded;
    mapping (address => bool) private _isLP;
    address private _primaryLP;
    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    bool private _tradingOpen;
    bool private _zeroTaxMode;
    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor() Auth(msg.sender) {
        _balances[_owner] = _totalSupply * 5 / 100;
        emit Transfer(address(0), _owner, _balances[_owner]);
        _balances[address(this)] = _totalSupply - _balances[_owner];
        emit Transfer(address(0), address(this), _balances[address(this)]);
        _excluded[_owner] = true;
        _excluded[address(this)] = true;
        _excluded[_swapRouterAddress] = true;
        _excluded[_walletMarketing] = true;
        _launchTime = uint32(block.timestamp)*2;
    }

    receive() external payable {}
    
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
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_primaryLP] = true;
        _tradingOpen = true;
        _launchTime = uint32(block.timestamp);
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        require(checkLimits(sender, recipient, amount), "Limits exceeded");
        if (!_tradingOpen) { require(_excluded[sender], "Trading not open"); }        
        if ( !_inTaxSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }
        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if ( _taxAmount > 0 ) { _balances[address(this)] += _taxAmount; }
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_excluded[sender]) { checkResult = true; } 
        return checkResult;
    }

    function checkLimits(address sender, address recipient, uint256 amount) private view returns (bool result) {
        result = true;
        if (!_excluded[recipient] && !_excluded[sender]) {            
            (uint256 maxTx, uint256 maxWallet) = limits();
            if (amount > maxTx) { result = false; }
            if (!_isLP[recipient] && _balances[recipient] + amount > maxWallet) { result = false; }
        }
    }
    function limits() public view returns (uint256 maxTxAmount, uint256 maxWalletAmount) {
        maxTxAmount = _totalSupply; 
        maxWalletAmount = _totalSupply;
        if (block.timestamp > _launchTime + 900) {
            maxTxAmount = _totalSupply; // unlimited forever (limited by max wallet anyway)
            maxWalletAmount = _totalSupply * 20 / 1000; // 2.0% forever
        } else if (block.timestamp > _launchTime + 600) {
            maxTxAmount = _totalSupply * 7 / 1000; // 0.7% for minutes 10-15
            maxWalletAmount = _totalSupply * 15 / 1000; // 1.5% for minutes 10-15
        } else {
            maxTxAmount = _totalSupply * 5 / 1000; //0.5% for first 10 minutes
            maxWalletAmount = _totalSupply * 10 / 1000; //1.0% for first 10 minutes
        }
    }

    function removeAllFees() external onlyOwner {
        _zeroTaxMode = true;
    }

    function _tax() private view returns(uint8) {
        uint8 taxPercentage;
        if (_zeroTaxMode) {
            taxPercentage = 0; //after "removeAllFees()" is called, permanent.
        } else if (block.timestamp > _launchTime + 900) {
            taxPercentage = 5; //0.5% tax after 15 minutes
        } else if (block.timestamp > _launchTime + 600) {
            taxPercentage = 50; //5% tax minutes 10-15
        } else if (block.timestamp > _launchTime + 180) {
            taxPercentage = 100; //10% tax minutes 3-10
        } else {
            taxPercentage = 250; //5% tax minutes 0-3
        }
        return taxPercentage;
    }

    function tax() external view returns (uint8) {
        return _tax()/10;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256 taxAmount) {
        if ( _tradingOpen && !_excluded[sender] && !_excluded[recipient] ) { 
            if ( _isLP[sender] || _isLP[recipient] ) {
                taxAmount = amount * _tax() / 1000;
            }
        }
    }

    function marketingWallet() external pure returns (address) {
        return _walletMarketing;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));
        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }
            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { 
                (bool sent, bytes memory data) = _walletMarketing.call{value: _contractETHBalance}("");
                sent = true; data = bytes("");
            }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
}

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}