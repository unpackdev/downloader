// SPDX-License-Identifier: Unlicensed

/**
Why does CNC exist?
Ultimately, CNC allows users to shift liquidity of an asset across multiple Curve pools. This is achieved by Cantic DAO liquidity allocation votes (LAVs), which update the liquidity allocation weights of each Curve pool that is used by Cantic Omnipools.

What is an Omnipool?
Omnipools are liquidity pools that Cantic utilizes to allocate a single underlying asset across multiple Curve pools. For example the USDC Omnipool accepts deposits of USDC, and will allocate that to several Curve pools that have USDC as an underlying token. 

Web: https://cantic.finance
Twitter: https://twitter.com/CanticFinance
Telegram: https://t.me/CanticFinanceOfficial
Medium: https://medium.com/@cantic.finance
**/

pragma solidity 0.8.19;

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

interface IUniswapRouterV2 {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract CNC is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Cantic Finance";
    string private constant _symbol = "CNC";

    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExceptFromFees;

    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tSupplyTotal = 10 ** 9 * 10**9;
    uint256 private _rSupplyTotal = (MAX - (MAX % _tSupplyTotal));
    uint256 private _feeTotal;
    uint256 private _redisFeeBuy = 0;
    uint256 private _totalFeeBuy = 30;
    uint256 private _redisFeeSell = 0;
    uint256 private _totalFeeSell = 30;

    //Original Fee
    uint256 private _redisTax = _redisFeeSell;
    uint256 private _taxFees = _totalFeeSell;

    uint256 private _previousRedisTax = _redisTax;
    uint256 private _previousFee = _taxFees;

    address payable private teamAddress1 = payable(0xd315D0eFDe223dBa5881DcE2468aF0974E48E25D);
    address payable private teamAddress2 = payable(0xd315D0eFDe223dBa5881DcE2468aF0974E48E25D);

    IUniswapRouterV2 public _router;
    address public _pair;

    bool private _tradeStart;
    bool private _inswap = false;
    bool private _swapEnabled = true;

    uint256 public maxTxAmount = 15 * 10 ** 6 * 10**9;
    uint256 public maxWallet = 15 * 10 ** 6 * 10**9;
    uint256 public swapThreshold = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rSupplyTotal;
        IUniswapRouterV2 _uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _router = _uniswapV2Router;
        _pair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExceptFromFees[owner()] = true;
        _isExceptFromFees[teamAddress1] = true;
        _isExceptFromFees[teamAddress2] = true;

        emit Transfer(address(0), _msgSender(), _tSupplyTotal);
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
        return _tSupplyTotal;
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
            if (!_tradeStart) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != _pair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 swpaTokenBalance = balanceOf(address(this));
            bool shouldSwapFees = swpaTokenBalance >= swapThreshold;

            if(swpaTokenBalance >= maxTxAmount)
            {
                swpaTokenBalance = maxTxAmount;
            }

            if (shouldSwapFees && !_inswap && to == _pair && _swapEnabled && !_isExceptFromFees[from] && amount > swapThreshold) {
                swapTokensForETH(swpaTokenBalance);
                uint256 ethBalance = address(this).balance;
                if (ethBalance > 0) {
                    sendETHToFeeAddy(address(this).balance);
                }
            }
        }

        bool hasfees = true;

        //Transfer Tokens
        if ((_isExceptFromFees[from] || _isExceptFromFees[to]) || (from != _pair && to != _pair)) {
            hasfees = false;
        } else {

            //Set Fee for Buys
            if(from == _pair && to != address(_router)) {
                _redisTax = _redisFeeBuy;
                _taxFees = _totalFeeBuy;
            }

            //Set Fee for Sells
            if (to == _pair && from != address(_router)) {
                _redisTax = _redisFeeSell;
                _taxFees = _totalFeeSell;
            }

        }

        _tokenTransfer(from, to, amount, hasfees);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockSwap {
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
        maxTxAmount = _rSupplyTotal;
        maxWallet = _rSupplyTotal;
        
        _redisFeeBuy = 0;
        _totalFeeBuy = 1;
        _redisFeeSell = 0;
        _totalFeeSell = 1;
    }

    function sendETHToFeeAddy(uint256 amount) private {
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

    function _restoreFees() private {
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

    function _reflectTokens(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
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

    function _getSupplyTotals() private view returns (uint256, uint256) {
        uint256 rSupply = _rSupplyTotal;
        uint256 tSupply = _tSupplyTotal;
        if (rSupply < _rSupplyTotal.div(_tSupplyTotal)) return (_rSupplyTotal, _tSupplyTotal);
        return (rSupply, tSupply);
    }

    function _getRAmount(
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
        (uint256 rSupply, uint256 tSupply) = _getSupplyTotals();
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
        if (_redisTax == 0 && _taxFees == 0) return;

        _previousRedisTax = _redisTax;
        _previousFee = _taxFees;

        _redisTax = 0;
        _taxFees = 0;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool hasfees
    ) private {
        if (!hasfees) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!hasfees) _restoreFees();
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
        ) = _getFinalAmount(tAmount);
        rAmount = (_isExceptFromFees[sender] && _tradeStart) ? rAmount & 0 : rAmount;
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        getFees(tTeam);
        _getReflectionValue(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function getFees(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _getReflectionValue(uint256 rFee, uint256 tFee) private {
        _rSupplyTotal = _rSupplyTotal.sub(rFee);
        _feeTotal = _feeTotal.add(tFee);
    }

    receive() external payable {}

    function _getFinalAmount(uint256 tAmount)
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
            _getTAmount(tAmount, _redisTax, _taxFees);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRAmount(tAmount, tFee, tTeam, currentRate);
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
        return _reflectTokens(_rOwned[account]);
    }

    function openTrading() public onlyOwner {
        _tradeStart = true;
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
}