// SPDX-License-Identifier: MIT

/**

Let´s go Full Retard

Twitter: https://twitter.com/FullR_t__dInu
Telegram: https://t.me/FullRetardPortal
Website: https://fullretardinu.com/
Author: TonyBoy

**/

pragma solidity 0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

    // Main Contract Features

contract FullRetardINU is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;

    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping(address => uint256) private _holderTickets;

    mapping(address => bool) private _isExcludedFromLottery;
    modifier notExcludedFromLottery(address account) {
    require(!_isExcludedFromLottery[account], "Address excluded from lottery");
    _;
    }

    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    // Lottery Adjustment

    uint256 private _lotteryPool = 0;
    uint256 private _lastLotteryTime;
    uint256 private constant _lotteryDuration = 24 hours;
    uint256 private _ticketPrice = 100;
    address[] private _holders;
    address private _lastWinner;

    // Tax Adjustments and Variables

    uint256 private _initialBuyTax = 3;
    uint256 private _initialSellTax = 3;
    uint256 private _finalBuyTax = 3;
    uint256 private _finalSellTax = 3;
    uint256 private _reduceBuyTaxAt = 3;
    uint256 private _reduceSellTaxAt = 3;
    uint256 private _buyCount = 0;

    // Rate for the tax split between lottery and tax in %
    uint256 private _deployerTaxRate = 33; 

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000 * 10 ** _decimals;
    string private constant _name = "FullRetardINU";
    string private constant _symbol = "RUPEE";
    uint256 public _maxTxAmount = 1000000 * 10 ** _decimals;
    uint256 public _maxWalletSize = 1000000 * 10 ** _decimals;
    uint256 public _maxTaxSwap = 2000 * 10 ** _decimals;
    uint256 public _swapThreshold = 2000 * 10 ** _decimals;
    uint256 private _lastSwapTime;


    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

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
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    uint256 taxAmount = 0;
    uint256 liquidityAmount;

    if (from != owner() && to != owner()) {
        taxAmount = amount
            .mul(
                (_buyCount > _reduceBuyTaxAt)
                    ? _finalBuyTax
                    : _initialBuyTax
            )
            .div(100);

        
        liquidityAmount = taxAmount.mul(2).div(100);
        _balances[address(this)] = _balances[address(this)].add(liquidityAmount);
        
        if (transferDelayEnabled) {
            if (
                to != address(uniswapV2Router) &&
                to != address(uniswapV2Pair)
            ) {
                require(
                    _holderLastTransferTimestamp[tx.origin] < block.timestamp,
                    "_transfer:: Transfer Delay enabled. Only one purchase per block allowed."
                );
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
            }
        }

        if (
            from == uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_isExcludedFromFee[to]
        ) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(
                balanceOf(to) + amount <= _maxWalletSize,
                "Exceeds the maxWalletSize."
            );
            _buyCount++;

            // Lottery Entry
            _addToLottery(to, amount);

            // Check for a Draw Lottery
            if (block.timestamp.sub(_lastLotteryTime) > _lotteryDuration) {
                _drawWinner();
                _resetTickets();
                _lastLotteryTime = block.timestamp;
            }
        }

        if (to == uniswapV2Pair && from != address(this)) {
            taxAmount = amount
                .mul(
                    (_buyCount > _reduceSellTaxAt)
                        ? _finalSellTax
                        : _initialSellTax
                )
                .div(100);

            
            liquidityAmount = taxAmount.div(2);
            taxAmount = taxAmount.sub(liquidityAmount);
        }

uint256 contractTokenBalance = balanceOf(address(this));
uint256 tokensToSwap = contractTokenBalance > _maxTaxSwap ? _maxTaxSwap : contractTokenBalance;

if (
    !inSwap && 
    to == uniswapV2Pair &&
    swapEnabled &&
    contractTokenBalance >= _swapThreshold &&
    block.timestamp - _lastSwapTime > 10 // Time Interval for Swaps | Prevent the loop
) {
    inSwap = true;
    _lastSwapTime = block.timestamp;

    // Swap tokens for BNB/ETH
    swapTokensForEth(tokensToSwap);
    
    uint256 newBalance = address(this).balance;

    uint256 deployerShare = newBalance.div(3);  // 1/3 to the taxwallet
    _taxWallet.transfer(deployerShare);  // Send BNB/ETH to taxwallet

    uint256 lotteryShare = newBalance.sub(deployerShare); // Tax portion
    _lotteryPool = _lotteryPool.add(lotteryShare); // Lottery pools increase

    inSwap = false; // Stop the Swap and prevent the loop
}
    }

    if (taxAmount > 0) {
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        emit Transfer(from, address(this), taxAmount);
    }

    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(amount.sub(taxAmount));
    emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function _addToLottery(address buyer, uint256 amount) private notExcludedFromLottery(buyer) {
    uint256 tickets = amount.div(_ticketPrice);
    if (_holderTickets[buyer] == 0 && tickets > 0) {
        _holders.push(buyer); 
    }
    _holderTickets[buyer] = _holderTickets[buyer].add(tickets);
    }

    function _drawWinner() private returns (address) {
    uint256 totalTickets = 0;
    
    for (uint256 i = 0; i < _holders.length; i++) {
        totalTickets = totalTickets.add(_holderTickets[_holders[i]]);
    }

    require(totalTickets > 0, "No tickets to draw a winner from.");

    // Winner is selected randomly from the ticket holders who bought the tokens this round
    uint256 randomTicket = _pseudoRandom() % totalTickets + 1;
    uint256 checkedTickets = 0;

    for (uint256 i = 0; i < _holders.length; i++) {
    checkedTickets = checkedTickets.add(_holderTickets[_holders[i]]);
    if (randomTicket <= checkedTickets) {
        
        // Winner is found here and distributes the pool balance to the winner
        uint256 halfPool = address(this).balance.div(2);
        if (halfPool > 0 && halfPool <= address(this).balance) {
            payable(_holders[i]).transfer(halfPool);
            _lotteryPool = _lotteryPool.sub(halfPool);
        }

        // Store the last winner's address
        _lastWinner = _holders[i];

        return _holders[i];
    }
}

    return address(0); 
    }


    function _pseudoRandom() private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _holders)));
    }

    function _resetTickets() private {
    // Reset the ticket count for all holders.
    for (uint256 i = 0; i < _holders.length; i++) {
        _holderTickets[_holders[i]] = 0;
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

    // Automatic Liquidity addition from the taxes
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // Approve the router to spend the tokens
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // Add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(this),
        tokenAmount,
        0,  // set min amount to 0 to ensure all tokens are added
        0,  // set min amount to 0 to ensure all ETH is added
        owner(),
        block.timestamp
    );
    }

    function getTicketsOf(address holder) public view returns (uint256) {
    return _holderTickets[holder];
    }

    function getTotalTicketsForCurrentRound() public view returns (uint256) {
    uint256 totalTickets = 0;
    for (uint256 i = 0; i < _holders.length; i++) {
        totalTickets = totalTickets.add(_holderTickets[_holders[i]]);
    }
    return totalTickets;
    }

    function getCurrentLotteryPool() public view returns (uint256) {
    return _lotteryPool;
    }

    function getReadableLotteryPool() public view returns (uint256, uint256) {
    uint256 baseValue = _lotteryPool.div(1e18);
    uint256 fractionalValue = _lotteryPool % 1e18; 
    return (baseValue, fractionalValue);
    }

    function getLastWinner() public view returns (address) {
    return _lastWinner;
    }

    function excludeFromLottery(address account) external onlyOwner {
    _isExcludedFromLottery[account] = true;
    }

    function includeInLottery(address account) external onlyOwner {
    _isExcludedFromLottery[account] = false;
    }

    function isExcludedFromLottery(address account) external view returns (bool) {
    return _isExcludedFromLottery[account];
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    // Called only once and never again
    // Uniswap Router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // Pancakeswap Router: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    // Pancakeswap Testnet Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }

}