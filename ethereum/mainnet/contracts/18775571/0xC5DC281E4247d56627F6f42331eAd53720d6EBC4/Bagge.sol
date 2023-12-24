// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// Local Imports
import "./IBagge.sol";

/*
............................................................................::..^JPPPPGGGPP555YYYJ?Y
..............................................................................^?PBBBBBBBBBBBBBBBBBBB
............................................................................:7PBBBBBBBBBBBBBBBBBBBBB
..........................................................................^7PBBBBBBBBBBBBBBBBBBBBBBB
................................................................:^^~!^..^?PBBBBBBBBBBBBBBBBBBBBBBBBB
...........................................................:^!JY5GGBBP?YGBBBBBBBBBBBBBBBBBBBBBBBBBBB
........................................................:!JPGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
........................................................!GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
...............................................:::^~~!7?YGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
......................................:~!7??JY55PPGGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBY?
....................................^?PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGP5P!.
................................:.:7PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGPYJ?7!!~~JJ.
.................................^YBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGPYJ?7!~~~^^^~~~~?Y:
..............................:.^5BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGGPYJ?7!~~^^^^^^~^~~~~~~~?Y:
................................?#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBGP5Y?7!~~~^^^^~~!!777?77!!~~~~~JJ.
..............................:.^PBBBBBBBBBBBBBBBBBBBBBBBBBBGPYJ?!~~~^^^~~~~~~!?JYYJJ????JJJJ?~~!5!.
.................................~PBBBBBBBBBBBBBBBBGGPBBGGPP5Y7~^~~~~~~~~~~~~?5?!~~~^^^^^^^~!5?~YJ:.
..................................^5BBBBBBBBBP5YJ?7!!~?7!~~~~!!!~~~~~~~~~~~^!P7~~~~~~~~~~~~~~J5YJ:..
............................:::^~!7YGPYJ?!~?GJ!^^^^~~~^^~!7!!~^^~~~^~~~~!7??5Y~~~~~~~~~~~~~~~J57:...
...................:^~!7?JJY5PGGGPJ7~:...:!YG57~~~~~~~~?YYYYJ??!~!77?JJJJ?7!J?~~~~~~~~~~~~~~!J~.....
.................:!YGBB##BBG5J7!^:......^J7^7Y~~~~~~~~JJ~^^~!77J5J??7!~~~^~~~!~~~~~~~~~~~~~~??:.....
...............:~YBBBPY?7~^::..........:~^..~PY?7~~~~~Y?^^^^^~7!JJ^^~^~~~~~~~~~~~~~~~~~~~~~!Y~......
.............:!5B#BY~:.....................~Y7?J?J?!7?55~^^^^^~?!5!~~7Y5Y?7~~~~~~~~~~~~~~~~J?:......
...........^75B#GY~:.......................!J^^^!7YPJ7!J57~^^^^7?5!~???P5!~~~~~~~~~~~~~~~~JJ:.......
.........~JPBBGJ~:.:.......................:J7^^^7P?~^^~7JJ?77J5J!~~~~~5P5!^~~~!~~~~~~~^!J?:........
......^!YB#B57^.............................:??~~JY~~~~~~~~!777!~~~~~^?P5PY~~~~!Y7~~~~!7?~:.........
...:!JGBBGJ~:..............................:.:~7JP7~~~~~~~~!!~~~~~~~~755Y5P?~~~~Y5????7~:...........
:~JPBBGY!^...................................:..!5!^~^^~!?YY!~~~~~~!JP5YYYPP!~~~?Y^:::..............
GBBPJ!^.........................................~57!!7?JPB5!~~~~~!YPP5YYYYYP?^~~!5!.................
Y7~:............................................:7??7!^:!5J!~~!7JJJP5YYYYYYP5~~~~Y?:................
.........................................................:!????7^..~YP5YY55PP!~~~JY:................
............................................................:::.:~!!?GGPPPPPP7~~~?5^................
...............................................................^J?!JPP55Y555P?^~~?5^................
..............................................................:7Y7YP5Y555Y55G?^~~?5~................
.......................................................^~^:::~???P5YY55PP5555!~~~?5~................
....................................................:~?J???7J5J?5P55YYJ?7!~!~~~~~JP~................
..................................................:~??!~~~~~~~!!!!~~~~~^^~~~~~~~~5P^................
.................................................^??!~~~~~~~~~~~~~~~~~~~~~~~~^~7Y57:................
...............................................:7J7~~~~~~~~~~~~~~~~~~~~~~~~~!?YJ!:..................
..............................................:?J!~~~~~~~~~~~~~~~~~~~~~~~!7JY7^.....................
.............................................^YJ~~~~~~~~~~~~~~~~~~~~~~~7JJ7~:.......................
............................................:YJ~~~~~~~~~~~~~~~~~~^~!7JJ7~:..........................
...........................................:JY~~~~~~~~~~~~~~~^~~!?JJ7^:.............................
...........................................!P!^~~~~~~~~~~~^~!7JJJ7^:................................
...........................................JY~~~~~~~~~~~!?JYY?!^....................................
..........................................:J?~~~~~!7?JYYY?!^:.......................................
...........................................!5JJJYJJJ?!~::...........................................
*/

/**
 * @title BaggeToken ~ It takes COURAGE to HODL your $BAGGE
 * @author Team M2xM ~ Your trustworthy dev.
 *
 * @notice https://t.me/baggeportal
 * 
 *         We strive to be very transparent. Because of this, we've left
 *         exhaustive documentation in the code to ensure holders know we are
 *         only ever going to do what is fair, honest and non-manipulative.
 * 
 *         Supply     = 8,000,000,000 (8 Billion)
 *         Initial LP = 1.8 ETH 🔥
 *         Uniswap LP = 7,600,000,000 (7.6 Billion, 95% of Supply)
 *         Dev Tokens = 400,000,000 (400 Million, 5% of Supply)
 *         Tax Rate   = 0.8% / 0.8% Tax -  This tax is auto-burned 🔥 
 *                      There is a 95% snipe buy tax, punishes snipes waiting for LQ pool opening as well is not waiting for taxes to be lifted.
 * 
 */
contract BAGGE is IBAGGE, Context, Ownable {
    using SafeMath for uint256;
    // @notice ~ Constant-related variables.
    string private constant _name = unicode"Eustace Bagge";             // @dev Token name: Eustace Bagge.
    string private constant _symbol = unicode"BAGGE";                   // @dev Token symbol: $BAGGE.
    uint8 private constant _decimals = 9;                               // @dev Needed for calculating large numbers.
    uint256 private constant _supply = 8000000000 * 10 ** _decimals;    // @dev 8 Billion $BAGGE tokens.

    // @notice ~ Tax-related variables.
    uint256 private constant _taxRate = 8;                               // @dev 0.8% Buy/Sell tax.
    uint256 private constant _snipeTaxRate = 950;                        // @dev Snipe Tax of 95% (Snipe prevention)
    uint256 private _autoBurnThreshold = 40000000 * 10 ** _decimals;     // @dev Auto burn threshold for when tax tokens should be burned. This is 0.5%

    // @notice ~ Transaction-related variables.
    uint256 private _maxAmountPerTx = 120000000 * 10 ** _decimals;       // @dev Initially 1.5% of supply, limit removed later.
    uint256 private _maxAmountPerWallet = 120000000 * 10 ** _decimals;   // @dev Initially 1.5% of supply, limit removed later.
    uint256 private _initialBlock;                                       // @dev Block number tracked to assure contract is fully set up before trading.                                   

    // @notice ~ Address-related variables.
    mapping(address => uint256) private _balances;                       // @dev Keeps track of balances of each user.
    mapping(address => mapping(address => uint256)) private _allowances; // @dev Keeps track of allowances of each user.
    mapping(address => bool) private _isExcludedFromFee;                 // @dev List of addresses that are excluded from fees.
    mapping (address => bool) private _bklist;                           // @dev Blacklist records, don't want to use this, but added if necessary.
    address payable private _deadWallet;                                 // @dev Deal wallet where token are auto burned after 1% tax is accumulated.
    address private uniswapV2Pair;                                       // @dev Address to UniswapV2Pair created by the contract.
    IUniswapV2Router02 private _uniswapV2Router;                         // @dev UniswapV2Router02 variable for LQ Pool & routing.

    // @notice Flag-related variables.
    bool private isTrading = false;                                      // @dev signals whether trading is enabled.
    bool private isSwapping = false;                                     // @dev signals whether a swap is currently in action.
    bool private isSwapEnabled = false;                                  // @dev signals whether swapping is enabled or not.
    bool private isLimitLifted = false;                                  // @dev signals whether or not the limited have been lifted.
    bool private isTaxLifted = false;                                    // @dev signals whether or not the tax limits have been lifted.

    /**
     * @notice Swap lock modifier to change the isSwapping state with a function in-between.
     */
    modifier SwapLock() {
        isSwapping = true;
        _;
        isSwapping = false;
    }

    /**
     * @notice Constructor, assure contract launcher is initial owner & set deal wallet address.
     */
    constructor() Ownable(_msgSender()) {
        // Give initial supply contract deployer.
        _balances[_msgSender()] = _supply;

        // Assign dead wallet.
        _deadWallet = payable(0x000000000000000000000000000000000000dEaD);

        // Exclude owner, contract and bbb wallet from fees.
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_deadWallet] = true;

        // Emit transfer event.
        emit Transfer(address(0), _msgSender(), _supply);
    }

    /**
     * @notice Return-related functions.
     */
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public pure override returns (uint256) {return _supply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    /**
     * @notice Override of IERC20::transfer. 
     *
     * @param recipient address of the recipient.
     * @param amount amount to transfer.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _internalTransfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice Override of IERC20::allowance. 
     *
     * @param owner address of the owner.
     * @param spender address of the spender.
     */
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Override of IERC20::approve. 
     *
     * @param spender address of the spender.
     * @param amount amount to approve.
     */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _internalApprove(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice Override of IERC20::transferFrom. 
     *
     * @param sender address of the sender.
     * @param recipient address of the recipient.
     * @param amount amount to approve.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _internalTransfer(sender, recipient, amount);
        _internalApprove(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "Can not exceed transfer allowance."
            )
        );
        return true;
    }

    /**
     * @notice Internal approve method that sets the allotment amount to map.
     * 
     * @param owner address of the owner.
     * @param spender address of the spender.
     * @param amount amount to approve.
     */
    function _internalApprove(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Internal transfer function with added tax capabilities.
     * 
     * @param from address of the sender.
     * @param to address of the recipient.
     * @param amount amount to transfer.
     */
    function _internalTransfer(address from, address to, uint256 amount) private {
        // Pre-check before transfer.
        require(from != address(0), "Can not transfer from the zero address");
        require(to != address(0), "Can not transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_bklist[from] && !_bklist[to], "Blocked from transferring, address flagged as bots");

        // Immediately finalize this transaction if [from] or [to] is in the excluded list with zero tax. excluded
        // parties are in the constructor.
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) return _finalizeTransfer(from, to, amount, 0);

        // Calculate taxRate.
        // Example: If purchasing 100000 tokens during early tax rate or 8 (or 0.8%):
        //      
        //      taxAmount = 100000 (amount) * tax rate (8 (or 0.8%)) = 2400000 / 1000 = 2400 tokens for tax.
        //      So 800 tokens will be sent to the contract address, you will receive 99200 Tokens.
        //     
        //      Tax is burning by the contract when contract reaches 0.5%% of supply. See _autoBurnBagge() function.
        uint256 taxAmount = amount.mul(_taxRate).div(1000);
        if (to != uniswapV2Pair && !isTaxLifted) {
            // Taxes have not yet been lifted and this is likely a buy, indicating this might be a snipe due to uniswap pool
            // as token contract has not yet been given. As such, snipe tax is applied instead.
            taxAmount = amount.mul(_snipeTaxRate).div(1000);
        }

        // Assure transfers from the UniSwapPair address to a holders wallet don't exceed the initially imposed
        // limits. These limits are later removed by liftLimits().
        if (from == uniswapV2Pair && to != address(_uniswapV2Router)) {
            require(amount <= _maxAmountPerTx, "Exceeds the transaction maximum.");
            require(balanceOf(to) + amount <= _maxAmountPerWallet, "Exceeds the wallet maximum.");

            // Block any user from being able to transfer until after the 4th block
            if (_initialBlock + 3 > block.number) require(!isContract(to));
        }

        // Assets balance of the to address is not above the allocated limit. Limit are removed later in the
        // liftLimits() function.
        if (to != uniswapV2Pair) require(balanceOf(to) + amount <= _maxAmountPerWallet, "Exceeds the wallet maximum.");

        // Facilitate that transaction into the contracts BAGGE balance.
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        emit Transfer(from, address(this), taxAmount);

        // Auto burn tokens collected in tax. This is dependent on 5 things:
        //  - Swapping is enabled.
        //  - Are limits lifted.
        //  - Not currently swapping.
        //  - [to] address is uniswapV2Pair.
        //  - token balance of the contract is larger than auto burn threshold (0.5% of supply).
        if (
            isSwapEnabled &&
            isLimitLifted &&
            isTaxLifted &&
            !isSwapping &&
            to == uniswapV2Pair &&
            balanceOf(address(this)) > _autoBurnThreshold
        ) _autoBurnBagge();

        // Finalize the transaction.
        _finalizeTransfer(from, to, amount, taxAmount);
    }

    /**
     * @dev Finalizes the _internalTransfer function.
     *
     * @param from address of the sender.
     * @param to address of the recipient.
     * @param amount amount to transfer.
     */
    function _finalizeTransfer(address from, address to, uint256 amount, uint256 tax) private {
        // Complete transfer transaction.
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(tax));
        emit Transfer(from, to, amount.sub(tax));
    }

    /**
     * @notice Minimum between two numbers.
     * 
     * @param a first number.
     * @param b second number.
     */
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    /**
     * @notice Validates whether or not the address is this contract or not.
     * 
     * @param account Address to validate.
     */
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    /**
     * @notice automatically transfers the contracts supply of $BAAGE tokens collected from tax to the null address.
     */
    function _autoBurnBagge() private SwapLock {
        // Complete transfer transaction.
        uint256 balance = balanceOf(address(this));
        _balances[address(this)] = _balances[address(this)].sub(balance);
        _balances[_deadWallet] = _balances[_deadWallet].add(balance);
        emit Transfer(address(this), _deadWallet, balance);
    }
    
    /**
     * @dev Removes the initial transaction and wallets amount limits imposed on construction. This allows a use
     *         to allocate as much tokens as they may desire.
     */
    function liftWalletLimits() external onlyOwner {
        // Assure thus function can't be called twice
        require(!isLimitLifted, "Limits have already been lifted, can not call this function twice.");

        // Allow wallets to accumulate as many token as they want
        _maxAmountPerTx = _supply;
        _maxAmountPerWallet = _supply;

        // Change lift limits status.
        isLimitLifted = true;
        emit WalletLimitsRevised(_supply);
    }

    /**
     * @dev Removes the initial transaction tax limits imposed on construction. This will reduce tax to 0.8%
     */
    function liftTaxLimits() external onlyOwner {
        // Assure thus function can't be called twice
        require(!isTaxLifted, "Limits have already been lifted, can not call this function twice.");

        // Do a one-time transfer of the contract's balance to the contract owner. This is mostly snipe tax collected
        // by the contract owner that will go back to community and various project initiatives.
        _internalTransfer(address(this), owner(), balanceOf(address(this)));

        // Change lift limits status.
        isTaxLifted = true;
        emit TaxLimitsRevised(_supply);
    }
    
    /**
     * @dev Adds all addresses passed to the function to the _bklist.
     * @param addList list of addresses to add to the bklist.
     */
    function addToBkList(address[] memory addList) public onlyOwner {
        for (uint i = 0; i < addList.length; i++) {
            _bklist[addList[i]] = true;
        }
    }

    /**
     * @dev Removes all addresses passed to the function from the _bklist.
     * @param removeList list of addresses to remove from the bklist.
     */
    function removeFromBkList(address[] memory removeList) public onlyOwner {
        for (uint i = 0; i < removeList.length; i++) {
            _bklist[removeList[i]] = false;
        }
    }

    /**
     * @dev Check if passed address is on the _bkList.
     * @param a address to check.
     */
    function isOnBkList(address a) public view returns (bool) {
        return _bklist[a];
    }

    /**
     * @notice Creates a liquidity pool using all of the Ethereum & BAGGE tokens stored in the contracts address.
     *
     * @dev This assures that the LQ is locked indefinitely when the contract is renounced. There is no way to drain
     *      the LQ pool afterward since the contract is the owner of the LQ pool and the contract will owner will be
     *      renounced.
     */
    function createUniLQPoolAndBeginTrading() external onlyOwner {
        // First check if trading has already begun
        require(!isTrading, "Trading has already begun");

        // Initialize Uniswap at the official UniswapV2Router02 address
        // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Creates the LQ Pair of BAGGE/ETH on Uniswap.
        _internalApprove(address(this), address(_uniswapV2Router), _supply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        // Adds all of the ETH currently allocated in this contract as well as all of the $BAGGE tokens in this to be
        // added to the LQ pool.
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);

        // Enable swapping.
        isSwapEnabled = true;

        // Enable trading.
        isTrading = true;

        // Store the first block number for tracking.
        _initialBlock = block.number;
    }

    /**
     * @dev Enables the contract to receive eth without call data
     */
    receive() external payable {}
}