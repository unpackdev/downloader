//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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

contract Capo is IERC20, Auth {
    string private constant _name         = "Inverse Capo ETF";
    string private constant _symbol       = "CAPO";
    uint8 private constant _decimals      = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);
    uint256 private _deployedTimer=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isBlackListed;
    mapping (address => bool) private _noFees;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    address payable private _walletTax;
    uint256 private constant _taxSwapMin = _totalSupply / 500000;
    uint256 private constant _taxSwapMax = _totalSupply / 1000;
  
    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxHoldingAmount = 10_000_001 * (10**_decimals);  // 1%
    uint256 public minHoldingAmount = 100_000 * (10**_decimals);     // 0.01%;
    
    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor() Auth(msg.sender) { 

        _balances[msg.sender] = (_totalSupply / 1000 ) * 60;        // 5% CEX + 1% CAPO Donation
        _balances[address(this)] = (_totalSupply / 1000 ) * 940;    // 94% LP

        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
        
        setTaxWallet(msg.sender);

        _walletTax = payable(msg.sender);
        _noFees[_walletTax] = true;
        _noFees[_owner] = true;
        _noFees[address(this)] = true;

        _deployedTimer = block.timestamp;
  
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        require(!isBlackListed[sender], "Sender Blacklisted");
        require(!isBlackListed[recipient], "Receiver Blacklisted");

        if (!_tradingOpen) { require(_noFees[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient]) { _swapTaxAndLiquify(); }

        if (limited && sender == _primaryLP) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount && balanceOf(recipient) + amount >= minHoldingAmount, "Forbid");
        }

        if (transferDelayEnabled) {
            if (recipient != _swapRouterAddress && recipient != _primaryLP) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount; 
        }

        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }    

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddress, type(uint256).max);
        }
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
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _getTimePassed() internal view returns (uint256) {
        return (block.timestamp - _deployedTimer);
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function setTaxWallet(address newTaxWallet) public onlyOwner {
        _walletTax = payable(newTaxWallet);
    }

    function setBlackList(address[] memory _users, bool set) public onlyOwner {
        for(uint256 i = 0; i < _users.length; i++){
            isBlackListed[_users[i]] = set;
        }
    }

    function removeLimits() external onlyOwner{
        limited = false;
        transferDelayEnabled=false;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {

        uint256 taxAmount = 0;
        if ( _tradingOpen && !_noFees[sender] && !_noFees[recipient] ) { 
            if ( _isLP[sender] || _isLP[recipient] ) {

                uint256 taxRate;
                uint256 timePassed = _getTimePassed();

                if(timePassed < 130){                // first 2 min
                    taxRate = 90;
                } else if(timePassed < 300){         // first 5min
                    taxRate = 40;
                } else if(timePassed < 900){         // first 15min
                    taxRate = 30;
                } else if(timePassed < 3600){        // first 60min
                    taxRate = 20;
                } else if (timePassed < 4 * 3600){   // first 4h
                    taxRate = 10;
                } else {                             // 0% tax after 4h
                    taxRate = 0;
                }

                taxAmount = (amount / 100) * taxRate;
            }
        }

        return taxAmount;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 
                bool success;
                (success,) = _walletTax.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
}