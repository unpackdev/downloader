/*
https://clawfinance.com/
https://t.me/ClawFinanceETH
*/
// SPDX-License-Identifier: MIT
pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract CLAW is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant deadAddress = address(0xdead);
    address public uniV2router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    bool private swapping;

    address public marketingWallet;
    address public developmentWallet;
    address public liquidityWallet;
    address public operationsWallet;

    uint256 public maxTransaction;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint public CurrentRound;
    uint256 public taxCollectedthisRound;
    uint RewardDistributionTime = 8 hours;
    bool public rewardsEnabled = false;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    uint256 private launchBlock;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyOperationsFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellOperationsFee;
    uint256 public sellBurnFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForOperations;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedmaxTransaction;

    mapping(address => bool) public automatedMarketMakerPairs;

    struct roundInfo{
        bool bl;
        uint256 amt;
    }

    struct HoldersInfo {
        uint256 lastClaimRound;
        uint256 lastBuy;
        uint256 startHoldingTimestamp;
        mapping(uint256 => roundInfo) roundInfo;
        uint256 lastCalculatedRound;
    }

    struct RewardRound {
        uint256 startTime;
        uint256 endTime;
        uint256 totalCollectedTax;
        bool claimsEnabled;
        address[] modifiers;
        uint256 totalweightedBalance;
    }

    mapping(address => HoldersInfo) public holderInfo;
    mapping(uint256 => RewardRound) public rewardsRound;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event operationsWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Claw Finance", "CLAW") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniV2router); 

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyMarketingFee = 25;
        uint256 _buyOperationsFee = 5;
    
        uint256 _sellMarketingFee = 35;
        uint256 _sellOperationsFee = 5;
        uint256 _sellBurnFee = 1;

        uint256 totalSupply = 75_000_000  * 1e18;
        
        maxTransaction = totalSupply * 2 / 100; // 2% max transaction at launch 
        maxWallet = totalSupply * 2 / 100; // 2% max wallet at launch
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

        buyMarketingFee = _buyMarketingFee;
        buyOperationsFee = _buyOperationsFee;
        buyTotalFees = buyMarketingFee+ buyOperationsFee;

        sellMarketingFee = _sellMarketingFee;
        sellOperationsFee = _sellOperationsFee;
        sellBurnFee = _sellBurnFee;
        sellTotalFees = sellMarketingFee + sellOperationsFee + sellBurnFee;

        marketingWallet =  address (0xE7c68d7E8870B640358425FC7897eCB762a7267A);

        operationsWallet = address(0xd7BCDb62fCb0e1C4A1f16996a9430601b5615D5d);

        CurrentRound = 1;

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Token launched");
        tradingActive = true;
        launchBlock = block.number;
        swapEnabled = true;

        rewardsRound[CurrentRound].startTime = block.timestamp;
        rewardsEnabled = true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxTransaction(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1000) / 1e18,
            "Cannot set maxTransaction lower than 0.1%"
        );
        maxTransaction = newNum * (10**18);
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 5) / 1000) / 1e18,
            "Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedmaxTransaction[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _operationsFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyOperationsFee = _operationsFee;
        buyTotalFees = buyMarketingFee + buyOperationsFee;
        require(buyTotalFees <= 50);
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _operationsFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellOperationsFee = _operationsFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellMarketingFee + sellOperationsFee + sellBurnFee;
        require(sellTotalFees <= 50); 
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updatemarketingWallet(address newmarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newmarketingWallet, marketingWallet);
        marketingWallet = newmarketingWallet;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function internalRoundDeets(address holder,uint _round) external view returns(roundInfo memory,address[] memory){
        HoldersInfo storage info = holderInfo[holder];
        return (info.roundInfo[_round],rewardsRound[_round].modifiers);
    }

    function forceStartNewRound() external {
        require(msg.sender == owner(), "Only owner can call this function");
        checkandUpdateRound(true);
    }

    function updateTotalWeight(uint256 _round, uint256 _weight) external onlyOwner{
        RewardRound storage round = rewardsRound[_round];
        round.totalweightedBalance = _weight;
    }

    function updateisRewardEnabled(bool _enabled) external onlyOwner{
        rewardsEnabled = _enabled;
    }

    function updateWeightedBalance(address holder,bool isSell) internal {
        if (!rewardsEnabled ) return;
        HoldersInfo storage info = holderInfo[holder];
        RewardRound storage round = rewardsRound[CurrentRound];
        uint256 weightedBalance;
        if (isSell){
            if (!info.roundInfo[CurrentRound].bl ){
                info.roundInfo[CurrentRound].bl = true;
                uint256 _temp_w= info.roundInfo[CurrentRound].amt;
                if (_temp_w == 0){
                    _temp_w = info.roundInfo[info.lastCalculatedRound].amt;
                }
                round.modifiers.push(holder);
                round.totalweightedBalance -= _temp_w;
                info.roundInfo[CurrentRound].amt = balanceOf(holder);
                info.lastCalculatedRound = CurrentRound;
            }
        }else{
            if (!info.roundInfo[CurrentRound].bl){
                uint256 timeHeld = block.timestamp - info.startHoldingTimestamp;
                weightedBalance = info.roundInfo[CurrentRound].amt;
                if (weightedBalance == 0){
                    weightedBalance = info.roundInfo[info.lastCalculatedRound].amt;
                }
                round.totalweightedBalance -= weightedBalance;
                weightedBalance = calculateWeightedBalance(balanceOf(holder), timeHeld);
                info.roundInfo[CurrentRound].amt = weightedBalance;
                round.totalweightedBalance += weightedBalance;
                info.lastCalculatedRound = CurrentRound;
                if (info.startHoldingTimestamp == 0) {
                    info.startHoldingTimestamp = block.timestamp;
                }
                if (info.lastBuy == 0){
                    info.lastClaimRound = CurrentRound - 1;
                }
                info.lastBuy = block.timestamp;
            }
        }
    }

    function calculateWeightedBalance(uint256 balance, uint256 timeHeld)
    internal
    pure
    returns (uint256 weightedBalance) {
        if (timeHeld >= 60 days) return (balance * 200) / 100; // bonus 100%
        if (timeHeld >= 45 days) return (balance * 190) / 100; // bonus 90%
        if (timeHeld >= 30 days) return (balance * 180) / 100; // bonus 80%
        if (timeHeld >= 20 days) return (balance * 170) / 100; // bonus 70%
        if (timeHeld >= 12 days) return (balance * 160) / 100; // bonus 60%
        if (timeHeld >= 7 days) return (balance * 150) / 100; // bonus 50%
        if (timeHeld >= 4 days) return (balance * 140) / 100; // bonus 40%
        if (timeHeld >= 3 days) return (balance * 130) / 100; // bonus 30%
        if (timeHeld >= 2 days) return (balance * 120) / 100; // bonus 20%
        if (timeHeld >= 1 days) return (balance * 110) / 100; // bonus 10%
        if (timeHeld >= 12 hours) return (balance * 105) / 100; // bonus 5%
        return balance;
    }

    function checkandUpdateRound(bool _force) internal {
        if (!rewardsEnabled) return;
        RewardRound storage round = rewardsRound[CurrentRound]; // Use storage directly

        if (block.timestamp >= round.startTime + RewardDistributionTime || _force) {
            round.endTime = block.timestamp;
            round.claimsEnabled = true;
            round.totalCollectedTax = taxCollectedthisRound;
            
            taxCollectedthisRound = 0;
            RewardRound storage next_round = rewardsRound[CurrentRound + 1];
            next_round.totalweightedBalance = round.totalweightedBalance;
            next_round.startTime = block.timestamp;
            for (uint256 i = 0; i < round.modifiers.length; i++) {
                address holder = round.modifiers[i];
                HoldersInfo storage info = holderInfo[holder];
                info.startHoldingTimestamp = block.timestamp;
                uint256 weight = balanceOf(holder);
                info.roundInfo[CurrentRound + 1].amt = weight;
                next_round.totalweightedBalance += weight;
                info.lastCalculatedRound = CurrentRound + 1;
            }
            delete round.modifiers; //release storage consumed by modifiers;

            CurrentRound++;
        }
    }


    function _claim(address _sender) internal {
        if (!rewardsEnabled ) return;
        rewardsEnabled = false; //protect from re-entrancy;
        checkandUpdateRound(false);
        HoldersInfo storage info = holderInfo[_sender];
        if (info.lastClaimRound >= CurrentRound - 1 && info.lastClaimRound != 0) {rewardsEnabled = true;return;}
        uint256 totalreward = 0;
        for (uint256 i = info.lastClaimRound + 1; i < CurrentRound; i++) {
            roundInfo memory _roundInfo = info.roundInfo[i];
            if (!_roundInfo.bl){
                RewardRound storage round = rewardsRound[i];
                if (!round.claimsEnabled){
                    break;
                }
                if (round.totalweightedBalance == 0) continue;
                uint256 _temp_weight;
                if (info.lastCalculatedRound < i){
                    _temp_weight = info.roundInfo[info.lastCalculatedRound].amt;
                }else{
                    _temp_weight = _roundInfo.amt;
                }
                uint256 reward = (_temp_weight * round.totalCollectedTax) / round.totalweightedBalance;
                if (info.lastCalculatedRound < i){
                    uint256 timeHeld = round.endTime - info.startHoldingTimestamp;
                    uint256 _tempreward = reward;
                    reward = calculateWeightedBalance(reward, timeHeld);
                    if (reward >= round.totalCollectedTax) reward = _tempreward;
                    if (round.totalCollectedTax > reward-_tempreward) round.totalCollectedTax -= (reward-_tempreward);
                    else round.totalCollectedTax = 0;
                }
                totalreward += reward;
            }
        }
        if (totalreward > 0){
            if (totalreward >= address(this).balance){
                totalreward = address(this).balance*25/100;
            }
            _sender.call{value: totalreward}("");
        }
        info.lastClaimRound = CurrentRound-1;
        rewardsEnabled = true;
    }

    function CalculateReward(address _user) public view returns (uint){
        if (!rewardsEnabled ) return 0;
        HoldersInfo storage info = holderInfo[_user];
        uint256 reward;
        uint256 totalReward;
        for (uint256 i = info.lastClaimRound + 1; i < CurrentRound; i++) {
            roundInfo memory _roundInfo = info.roundInfo[i];
            if (!_roundInfo.bl){
                RewardRound storage round = rewardsRound[i];
                if (!round.claimsEnabled){
                    break;
                }
                uint256 _temp_weight;
                if (info.lastCalculatedRound < i){
                    _temp_weight = info.roundInfo[info.lastCalculatedRound].amt;
                }else{
                    _temp_weight = _roundInfo.amt;
                }
                reward = (_temp_weight * round.totalCollectedTax) / round.totalweightedBalance;
                if (info.lastCalculatedRound < i){
                    // Extra Calculation to maintain fairness
                    uint256 timeHeld = round.endTime - info.startHoldingTimestamp;
                    uint256 _tempreward = reward;
                    reward = calculateWeightedBalance(reward, timeHeld);
                    if (reward >= round.totalCollectedTax) reward = _tempreward;
                }
                totalReward += reward;
            }
        }
        return totalReward;
    }

    function Claim() external {
        _claim(msg.sender);
        updateWeightedBalance(msg.sender, false);

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedmaxTransaction[to]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Buy transfer amount exceeds the maxTransaction."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedmaxTransaction[from]
                ) {
                    require(
                        amount <= maxTransaction,
                        "Sell transfer amount exceeds the maxTransaction."
                    );
                } else if (!_isExcludedmaxTransaction[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForOperations += (fees * sellOperationsFee) / sellTotalFees;
                super._transfer(from, deadAddress, (fees * sellBurnFee) / sellTotalFees); //burn
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForOperations += (fees * buyOperationsFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }
        // sell and set reward to false
        super._transfer(from, to, amount);
        if ((from == address(this) || to == address(this)) || from == to ) return;
        if (automatedMarketMakerPairs[to]){
            _claim(from);
            updateWeightedBalance(from, true);
        }else if (automatedMarketMakerPairs[from]){
            _claim(to);
            updateWeightedBalance(to, false);
        }else{
            _claim(from);
            updateWeightedBalance(from, true);
            updateWeightedBalance(to, false);
        }

        checkandUpdateRound(false);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function WithdrawETH(uint256 _amount) external  {
        require(msg.sender == marketingWallet, "Only marketing wallet can call this function");
        if (_amount == 0) {
            _amount = address(this).balance;
        }
        payable(msg.sender).transfer(_amount);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing +
            tokensForOperations;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 amountToSwapForETH = contractBalance;

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarket = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);


        tokensForMarketing = 0;
        tokensForOperations = 0;

        (success, ) = address(marketingWallet).call{value: ethForMarket}("");
        taxCollectedthisRound += (ethBalance - ethForMarket);
    }
}