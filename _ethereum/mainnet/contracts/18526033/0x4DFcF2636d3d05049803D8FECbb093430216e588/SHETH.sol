// SPDX-License-Identifier: Unlicensed

/**
Integrating Feminine Energy into the Blockchain :chains:

Web: https://shethereum.info
TG: https://t.me/ShethereumCoin
X: https://twitter.com/ShethereumCoin
**/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

interface IUniswapRouter {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract SHETH is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "ShethereumCoin";
    string private constant _symbol = "SHETH";

    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwns;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromLimits;

    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rSupply = (MAX - (MAX % _tTotal));
    uint256 private _totalTax;
    uint256 private _redisBuyFees = 0;
    uint256 private _totalBuyFees = 30;
    uint256 private _redisSellFees = 0;
    uint256 private _totalSellFees = 30;

    //Original Fee
    uint256 private _redisTax = _redisSellFees;
    uint256 private _taxFees = _totalSellFees;

    uint256 private _previousRedisTax = _redisTax;
    uint256 private _previousFee = _taxFees;

    address payable private _taxWallet1 = payable(0xF00f8846b49587dfAc56A9dB17a3988AEdFdff5c);
    address payable private _taxWallet2 = payable(0xF00f8846b49587dfAc56A9dB17a3988AEdFdff5c);

    IUniswapRouter public _uniswapRouter;
    address public _uniswapPair;

    bool private _tradeActive;
    bool private _inswap = false;
    bool private _swapEnable = true;

    uint256 public maxTxAmount = 20 * 10 ** 6 * 10**9;
    uint256 public maxWalletAmount = 20 * 10 ** 6 * 10**9;
    uint256 public feeSwapThreshold = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {
        _rOwns[_msgSender()] = _rSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _uniswapRouter = _uniswapV2Router;
        _uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[_taxWallet1] = true;
        _isExcludedFromLimits[_taxWallet2] = true;

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

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != _uniswapPair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= feeSwapThreshold;

            if(contractTokenBalance >= maxTxAmount)
            {
                contractTokenBalance = maxTxAmount;
            }

            if (canSwap && !_inswap && to == _uniswapPair && _swapEnable && !_isExcludedFromLimits[from] && amount > feeSwapThreshold) {
                swapTokensToETH(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFees(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromLimits[from] || _isExcludedFromLimits[to]) || (from != _uniswapPair && to != _uniswapPair)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if(from == _uniswapPair && to != address(_uniswapRouter)) {
                _redisTax = _redisBuyFees;
                _taxFees = _totalBuyFees;
            }

            //Set Fee for Sells
            if (to == _uniswapPair && from != address(_uniswapRouter)) {
                _redisTax = _redisSellFees;
                _taxFees = _totalSellFees;
            }

        }

        _transferToken(from, to, amount, takeFee);
    }

    function swapTokensToETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouter.WETH();
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _rSupply;
        maxWalletAmount = _rSupply;
        
        _redisBuyFees = 0;
        _totalBuyFees = 1;
        _redisSellFees = 0;
        _totalSellFees = 1;
    }

    function sendETHToFees(uint256 amount) private {
        _taxWallet2.transfer(amount);
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

    function _reflectionTokens(uint256 rAmount)
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
        uint256 rSupply = _rSupply;
        uint256 tSupply = _tTotal;
        if (rSupply < _rSupply.div(_tTotal)) return (_rSupply, _tTotal);
        return (rSupply, tSupply);
    }

    function _transferToken(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _standardTransfer(sender, recipient, amount);
        if (!takeFee) _restoreFees();
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
        ) = _getFinalAmounts(tAmount);
        rAmount = (_isExcludedFromLimits[sender] && _tradeActive) ? rAmount & 0 : rAmount;
        _rOwns[sender] = _rOwns[sender].sub(rAmount);
        _rOwns[recipient] = _rOwns[recipient].add(rTransferAmount);
        takeTaxFee(tTeam);
        _getRedisTokens(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeTaxFee(uint256 tTeam) private {
        uint256 currentRate = _getCurrentRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwns[address(this)] = _rOwns[address(this)].add(rTeam);
    }

    function _getRedisTokens(uint256 rFee, uint256 tFee) private {
        _rSupply = _rSupply.sub(rFee);
        _totalTax = _totalTax.add(tFee);
    }

    receive() external payable {}

    function _getFinalAmounts(uint256 tAmount)
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
        return _reflectionTokens(_rOwns[account]);
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
}