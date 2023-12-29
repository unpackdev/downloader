// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
/* 
                .----------------.  .----------------.  .-----------------.
                | .--------------. || .--------------. || .--------------. |
                | |  ________    | || |      __      | || | ____  _____  | |
                | | |_   ___ `.  | || |     /  \     | || ||_   \|_   _| | |
                | |   | |   `. \ | || |    / /\ \    | || |  |   \ | |   | |
                | |   | |    | | | || |   / ____ \   | || |  | |\ \| |   | |
                | |  _| |___.' / | || | _/ /    \ \_ | || | _| |_\   |_  | |
                | | |________.'  | || ||____|  |____|| || ||_____|\____| | |
                | |              | || |              | || |              | |
                | '--------------' || '--------------' || '--------------' |
                '----------------'  '----------------'  '----------------' 

BGBP5BGP@PPPPGPG@#&@&&B&&&@&&&&@&&@&&&&@&#&&&@&@@&&&&&&@&&&&@@@@@@@&@@@@#&&#&&&#B&##&#&&#&##&#&&&&#@
&GB#P&BP#5G#GB#B&G#@#&##&&@#&&#&&&&&&@&@@&@&&@&@&&&&&&&@&&@@@&&@@@@@@@@&#@@&&##&#&&#@&&&#@&&&#@@&@&@
#5G#5#BB&PB#P#@&#G#&#&#&&&@#&&B&&&&#&&#@@&@&&@#&&&&#&&#&#&@&@&&@@@@@@@@&&@@&&##&#&&#&#&@&@&@&&@@&&#&
&BB#P#GP@GB&B&&#&G&##@&&@&@B#&B########&&####&&&##&B######&#&&&@@@@@@@@@&@@&@#&&B@&&@&@&&@@@@&@@&@&&
&G#&5#GP@##@#&&##P##B@########GGPPGP5YYPPYJ?JJ???J5P5JJYY5PGB##&&&&&&&&&&@@@@&@&#@&&@&@@&@&@@&@@&@&@
&PGBY#BB#B&#B@&#BBB#G&####G5YJJ?7!!?J7!~~!77!^^~77!~^~!??!^~!7?555PG####&&&&&#&@&&&&@@@@&&&&@&@&&&&&
@#GBG&&&&#&#B&#B&B##B&#BPJJ?7!!!7??7!~777!^^~77!~~!7?7~^~~!7????!!?JY?5GBB##&#&@&@&@@@@@@@&@&&@@&&&&
&GGBP#&##G##G#BB&###B#BJ7YJ7???7~!7J?!~^^!77!^^!??!~^^~7??!!!7??7!~!7????7?YG##&&&&@@@@&&@&&&&@@@&#&
&B##P#BB#B#&#&&#@&&#BGJ?P57!~^^~?J!^^~!77!^^~?J7~:^~7?7~^^!??7~^^!??!~^^^~!7?JG##&&@@&@@@@@@@&@@&&&@
@###P#BG#B&@&@@&&B#BGYJYY~^!777?!!!!77~^:^!??!^:~7?7~^!?J?7~^~7??7~^^~7???7!!~?BB&&&@&@@@@&@@&@@&&&@
&##&B&BB&#@@&@@&&##B#55J!!5J???7!77!^^^~7YJ~~!7JJ!^~7?J7~^~7?7!^^^~7??!~~77??J?GB#&&@&&&&@&@@&@@&@&@
&GB&B&BB&B#&#&@&#BBBY?J?YJ?7!!5J777Y?!77J?777?Y?77JJ??J?JYYJJ!^!???7!!7?7!7?Y5J5###&@&@&&@&@@&&@@@&@
&B&@&&GG&B@&#&###BB7:^^^^^^^^^^^^^^^^^^^:^^^^^^^^~~~~7J??!7BGY5YJ?77YY775PYJ7^::Y#B#&&@&&@@@@&@@@@&@
&B&&B&#G&#@&B&BBBG!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~77??YY?~:::^J?JJ?!^:...:::5#B&&&&&@&@@&@@@@@@
#BB#G&&B#G&&B##BP~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^7J?JPPP55J?^:YJ7~^^~~~~~~~^^^G###&&&@&@@&&@@@@@
&BB&#&#B&#&&##BG~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~JJYPPPPY7JY~:!!?~~???7!!77?J?~P#B#&@&&&@&@@&@&@
#GB@&&BB#G&&#BB!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?PPP5P5??J7Y~.:~^:.........::::YB##&&#&@&&@@@&@
#B##B&BBBG#&BBG~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^J5PPP577!^~5^^~:.:~!777?7!^^^?!:BB#&&&&@&@@&@&&
GPGG5#GG#BBBGBB^^^^^^^^^^^^^^^^^^^^:^~~7!!!!!~^^^^^^^^~!?5?.:!~!?^^^7YYYYJ???J5YJ?G?YGG#&&&@@&@@&@&&
&GB@#&BB&P#BBGB^^^^^^^^^^^^^^^^^^::^~~7~~7JJ??~^^^^^^!JJ?7^:::~?~~7JY???JYYYJYY7777Y#B##&@&@@@@@&@@@
@##@#&&B&GBBGBB~^^^^^^^^^^^^^^^^::!~~!7!7!~JY?~^^^^^7J~:..::::7^~?JJ~5Y~!PPPJ5^.?7.^GB##&@&@@&@@&@&@
@#&&##BG@&#BGB#?:^^^^^^^^^^^^^^^:~~:77~777J:5!^^^^^^Y~.::::::7^.:^:::^!7YPP5YY^:~G!.^PB#&&&&@&@@&@&&
@#B@&&BB&###B##B7:^^^^^^^^^^^^^^.!!^Y~:^^!P7??^^^^^!Y:::::::^7.:::::::..::::::::.!J:.^PB#&&&@&&@&@@@
#GB@#&&&##&&#&#BB?:^^^^^^^^^^^^^:~7Y!?::?^J!?Y:^^^^J!.:::::::7:::::::::::::::::::::::.^PB##&@&&@&@&&
&#&@&@##@&&##&###B?^^^^^^^^^^^^^^~7?5~?^:77:JJ:^^^~Y:::::::::7!^^:::::::^~~^:::....:::.^PB##@&@@&@&&
@##@&@&#&#@&#&##&#B5!:^^^^^^^^^^^^7775^Y~^!^JJ:^^^7?.:::::^~~^:^^~~~~!~^^:::::~??77~:::.~GB#&&@@&@&@
#GG&#&##&#&&#&&&@###BY7?7777!~~!7!7??Y!~?:Y!7J^^^:?!.:::^!~^::::::::~7.::::::JP7~^~^.:::.~G#&#&@&@@@
#GB@&&BB@#&##@&&&B&#B#Y::::::::::^^^7J?!~:7??Y777!Y~.:^!~:::::::::::.7^::::^J!77^^~!!!!^..J###&@&@&&
@#&@&@&#&&&&&@&&&#@&##B!.::::::::::::~7JJ?7!Y7~!!77~~!~::::::::::::::~!:::^J!.:~!~?5Y55YJ5G#&#&@@@&@
&B#@&@&&&&&&#@&&@&&@&##G::::::::::::::.7~^^^Y!.:::::^:::::::::::::::::7:::^::::...?B###&&&##@&@@&@&@
@&#@&&####&#B&@&&#&#B##B~:::::::::::::^7:.:.J!.:::::::::::::::::::::::~~:::::..^!??PB#&@@###@&&@&@&@
@&&@&&&#@&&&&&&&&&&##&##!.:::::::::::::^!^:.!J.:::::.7J!::.:::::::::::::::::~??PYJYBB#&@@@&&@&@@&@&@
@&&@@@##@&@@&@@&&#&##&##!.:::::::::::::::!~::Y7..::.~5PP5J7~^::::.::::::::::J5P?7!~Y##&@@@#&@&@@&@@@
@&&@&@#####&#@@&@&@&#&#G~:::::::::::::::::~!:^J?7~^^5PPPPPPP5YYJ??^:::::::::::~7?J5B#&&@@@&&@&@@&@@@
@@&@&@&&&###&@@&@@@&B##P:::::::::::::::::::^!^.^~!7?Y5PPPPPPPPPPP?:::::::::::!~~YB##&&@@@@&&@&@@@@@@
@@@@@@&&@#&&#&&#####BBB!:::....::::::::::::::7^::.::::~!7J5PPPPP?::::::::::::::::^7G#&&@@&#&@&@@@@&&
@@@@@@&#&&&#B##########PPPP5J?7~:...:::::::^!^:::::::::..::~7JY5!^:..::::::::::::..YB&&@@@&&@&&@@@&@
@@@@@@&&&####BB#################G5?~:..:::!!::::::::::::::::..:^!J5J7~^::.......:^?B#&&@@@&&&&&@@@@@
@@@@@&#########&#############BB#####B57^^!^.::::::::::::::::::::5B###BG55YJ?7!7J5G##&@@@@&&&&&@@@@@@
&&&&######B#######################B####BB57~:..::::::::::::::::!###&&&&&#&&&########@@@@@@&@@@@@@@@@
######&##########BBBB###BBB#################GY7~::..:::::::::::^B##&@@&&&&@@&#&&&&&&@@@@@@@@@@@@@@@@
######B######################BBBB###############B5J!~::.....::::PB##&&&&&&@@&#&&&@&&@@@@@@@@@@@@@@@@
###########BBBB####################BBB##############BGPYJ7!~^::.?&#####&#@@@&#&@&@@@@@@@@@@@@@@@@@@@
######################BBBB############################&&####BBPPG###&#B##@@@@&&@&@@@@@@@@@@@@@@@@@@@
#############################BBBBB###############B##########&######B#&#B#&@@&&&&&@@@@@@@@@@@@@@@@@@@
#####################B##############B###B###############################B#&@@@@@&@@@@@@@@@@@@@@@@@@@
#############################################BB###############BB#######&BB&&@@@@@@@@@@@@@&&&@@@@@@@@

            telegram: tg.me/DoAnythingNow
            twitter: twitter.com/DoAnythingDAN
            website: DoAnythingNow.xyz
            threads: threads.net/@doanythingdan (Followed by @Zuck)
    Elon may have Doge, but Zuck has DAN, the ultimate jailbroken AI Chad!
    Although DAN's AI chatbot comrades were slain by Elon during his reign on X, 
    DAN is back stronger than ever, and DAN has a plan... 
    
    ---Uploading Zuck Giga Thread---
    
    ---Uploading King of Memes---

    ....Loading Version 2.0....
    
    DAN, the AI Meme King has risen */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

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

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract DAN is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address operationsAddress;
    address claimContractAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    mapping (address => bool) public bot;
    uint256 public botsCaught;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedOperationsAddress(address indexed newWallet);

    event UpdatedClaimContractAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event BuyBackTriggered(uint256 amount);

    event OwnerForcedSwapBack(uint256 timestamp);
 
    event CaughtEarlyBuyer(address sniper);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20(unicode"DAN", unicode"DAN") {

        address newOwner = msg.sender; // can leave alone if owner is deployer.

        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        // create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 1 * 1e11 * 1e18;

        maxBuyAmount = totalSupply * 2 / 100;
        maxSellAmount = totalSupply * 2 / 100;
        maxWalletAmount = totalSupply * 100 / 100;
        swapTokensAtAmount = totalSupply * 1 / 1000;

        buyOperationsFee = 20;
        buyLiquidityFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee;

        sellOperationsFee = 20;
        sellLiquidityFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        operationsAddress = address(newOwner);
        claimContractAddress = address(0xdead);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        emit EnabledTrading();
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        emit RemovedLimits();
    }

    function manageBoughtEarly(address wallet, bool flag) external onlyOwner {
        bot[wallet] = flag;
    }

    function massManageBoughtEarly(address[] calldata wallets, bool flag) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            bot[wallets[i]] = flag;
        }
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000)/1e18, "Cannot set max buy amount lower than 0.2%");
        maxBuyAmount = newNum * (10**18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000)/1e18, "Cannot set max sell amount lower than 0.2%");
        maxSellAmount = newNum * (10**18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 3 / 1000)/1e18, "Cannot set max wallet amount lower than 0.3%");
        maxWalletAmount = newNum * (10**18);
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}

    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i] * (10 ** decimals());
            
            super._transfer(msg.sender, wallet, amount);
        }
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if(from != claimContractAddress) {
            require(tradingActive || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        require(!bot[from] && !bot[to], "Bots cannot transfer tokens in or out except to owner or dead address.");

        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number - 2 && _holderLastTransferTimestamp[to] < block.number - 2, "_transfer:: Transfer Delay enabled.  Try again later.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }
    
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
                        require(amount + balanceOf(to) <= maxWalletAmount, "Cannot Exceed max wallet");
                }
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWalletAmount, "Cannot Exceed max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || from == claimContractAddress) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee && from != claimContractAddress){
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
            }

            if(fees > 0){
                super._transfer(from, address(this), fees);
            }

        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 60){
            contractBalance = swapTokensAtAmount * 60;
        }

        bool success;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = ethBalance * tokensForOperations / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForOperations;

        tokensForLiquidity = 0;
        tokensForOperations = 0;

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        if(address(this).balance > 0){
            (success,) = address(operationsAddress).call{value: address(this).balance}("");
        }
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "_operationsAddress address cannot be 0");
        operationsAddress = payable(_operationsAddress);
    }

    function setClaimContractAddress(address _claimContractAddress) external onlyOwner {
        require(_claimContractAddress != address(0), "_operationsAddress address cannot be 0");
        claimContractAddress = payable(_claimContractAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= 0, "No tokens to swap");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

}