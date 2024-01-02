/**

Once you got some $JAIL tokens, you enter the prison.

website: https://0xjail.com/
twitter: https://twitter.com/jailtokenerc20
telegram: https://t.me/jailportal

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router02 {
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

contract Jail is Context, IERC20, Ownable, VRFConsumerBaseV2 {

    using SafeMath for uint256;

    string private constant _name = "JAIL";
    string private constant _symbol = "JAIL";
    uint8 private constant _decimals = 18;

    VRFCoordinatorV2Interface vrfCoord;
    uint64 private _vrfSubscriptionId;
    bytes32 private _vrfKeyHash;
    uint16 private _vrfNumBlocks = 3;
    uint32 private _vrfCallbackGasLimit = 600000;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _rTotalNT = (MAX - (MAX % _tTotal));
    uint256 private _rTotalX = (MAX - (MAX % _tTotal));
    uint256 private _rTotalY = (MAX - (MAX % _tTotal));
    uint256 private _rTotalZ = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 private MINUTE = 60;
    uint256 private HOUR = 60 * MINUTE;
    uint256 public teamXTime = 60 * MINUTE;
    uint256 public teamYTime = 480 * MINUTE;
    uint256 public teamZTime = 60 * MINUTE;


    uint256 public _redisFeeOnBuy = 0;
    uint256 public _taxFeeOnBuy = 15;
    uint256 public _redisFeeOnSell = 0;
    uint256 public _taxFeeOnSell = 15;
    uint256 public _taxFeeEscaped = 0;
    uint256 public _taxFeeNotEscaped = 15;

    uint256 public _escapeTaxDuration = 6 * 60 * 60;
    mapping(address => bool) public userTryingEscape;
    mapping(address => uint256) public escapingTimestamp;
    mapping(address => bool) public userEscaped;
    mapping(uint256 => address) public escapeRequests;
    mapping(address => bool) public escapeRequested;


    mapping(address => uint256) public buyTime;
    mapping(address => uint256) public sellTime;
    uint256 topHolderAmount = 0;

    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    mapping (address => uint256) public _buyMap;
    address payable private _marketingAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = true;

    uint256 public _maxTxAmount = _tTotal * 2 / 100;
    uint256 public _maxWalletSize =  _tTotal * 2 / 100;
    uint256 public _swapTokensAtAmount = 1000000 * 10**_decimals;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    enum Team {
        X,
        Y,
        Z,
        NONE
    }

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash) VRFConsumerBaseV2(_vrfCoordinator)  {


        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _marketingAddress = payable(owner());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0xdead)] = true;
        _isExcludedFromFee[_marketingAddress] = true;

        vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
        _vrfSubscriptionId = _subscriptionId;
        _vrfKeyHash = _keyHash;

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

    function balanceOfNoReflection(address account) public view returns (uint256)  {
        uint256 balanceNR = _rOwned[account].div(_rTotal.div(_tTotal));
        return balanceNR;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account], account);
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

    function getTeam(address sender) view public returns(Team) {
        if (_isExcludedFromFee[sender] || address(uniswapV2Pair) == sender || address(uniswapV2Router) == sender) {
            return Team.NONE;
        }
        if (balanceOfNoReflection(sender) > topHolderAmount * 80 / 100 &&
            block.timestamp - buyTime[sender] > teamZTime) {
            return Team.Z;
        }
        if (sellTime[sender] == 0 &&
        block.timestamp - buyTime[sender] > teamYTime &&
            balanceOfNoReflection(sender) > totalSupply() * 100 / 100000) {
            return Team.Y;
        }
        if (sellTime[sender] == 0 && block.timestamp - buyTime[sender] > teamXTime && buyTime[sender] > 0) {
            return Team.X;
        }

        return Team.NONE;
    }

    function tokenFromReflection(uint256 rAmount, address account)
    private
    view
    returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate(account);
        return rAmount.div(currentRate);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
    {
        _escape(randomWords[0], escapeRequests[requestId]);
    }

    function escape() public {
        require(balanceOf(msg.sender) > 0, "Balance should be more than 0");
        require(!escapeRequested[msg.sender], "You already requested escape");
        uint256 reqId = vrfCoord.requestRandomWords(
            _vrfKeyHash,
            _vrfSubscriptionId,
            _vrfNumBlocks,
            _vrfCallbackGasLimit,
            uint16(1)
        );
        escapeRequests[reqId] = msg.sender;
        escapeRequested[msg.sender] = true;
    }

    function _escape(uint256 randomNumber, address holder) private returns(bool) {
        bool _escaped = randomNumber % 2 == 0;
        userTryingEscape[holder] = true;
        escapingTimestamp[holder] = block.timestamp;
        userEscaped[holder] = _escaped;
        return _escaped;
    }

    function getEscapeSecondsLeft(address holder) public view returns (uint256) {
        if (escapingTimestamp[holder] == 0) {
            return 0;
        }

        if (block.timestamp - escapingTimestamp[holder] >= _escapeTaxDuration) {
            return 0;
        }
        return _escapeTaxDuration - (block.timestamp - escapingTimestamp[holder]);
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
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount <= _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        //Transfer Tokens
        address transferAccount = to;
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
                if (balanceOfNoReflection(to) + amount > topHolderAmount) {
                    topHolderAmount = balanceOfNoReflection(to) + amount;
                }
                buyTime[to] = block.timestamp;
                transferAccount = to;
            }
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
                if(userTryingEscape[from]) {
                    if(block.timestamp - escapingTimestamp[from] <= _escapeTaxDuration) {
                        if (userEscaped[from]) {
                            _redisFee = _taxFeeEscaped;
                            _taxFee = 0;
                        } else {
                            _redisFee = _taxFeeNotEscaped;
                            _taxFee = 0;
                        }
                    }
                }
                sellTime[from] = block.timestamp;
                transferAccount = from;
            }

        }
        _tokenTransfer(from, to, amount, takeFee, transferAccount);
        if(userTryingEscape[from]) {
            if(block.timestamp - escapingTimestamp[from] > _escapeTaxDuration) {
                userTryingEscape[from] = false;
                escapeRequested[from] = false;
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForEthForUser(address holder) private lockTheSwap {
        uint256 tokenAmount = balanceOfNoReflection(holder);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(holder, address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            holder,
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function manualswap() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }


    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;

        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;

        _redisFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee,
        address account
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount, account);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        address account
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount, account);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam, account);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam, address account) private {
        uint256 currentRate = _getRate(account);
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(0);
        _rTotalX = _rTotalX.sub(rFee * 20 / 100);
        _rTotalY = _rTotalY.sub(rFee * 30 / 100);
        _rTotalZ = _rTotalZ.sub(rFee * 50 / 100);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount, address account)
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
                        _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate(account);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
                        _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
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

    function _getRate(address account) private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(account);
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply(address account) private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        if (getTeam(account) == Team.X) {
            rSupply = _rTotalX;
        }
        if (getTeam(account) == Team.Y) {
            rSupply = _rTotalY;
        }
        if (getTeam(account ) == Team.Z) {
            rSupply = _rTotalZ;
        }
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal))
            return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        require(redisFeeOnBuy + taxFeeOnBuy < 30);
        require(redisFeeOnSell + taxFeeOnSell < 30);
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    function updateMarketingWallet(address marketingWallet) public onlyOwner {
        _marketingAddress = payable(marketingWallet);
    }


    function updateKeyHash(bytes32 keyHash) public onlyOwner {
        _vrfKeyHash = keyHash;
    }

    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }

    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        require(maxTxAmount > 10000000 * 10**_decimals);
        _maxTxAmount = maxTxAmount;
    }

    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        require(maxWalletSize > 10000000 * 10**_decimals);
        _maxWalletSize = maxWalletSize;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

}
