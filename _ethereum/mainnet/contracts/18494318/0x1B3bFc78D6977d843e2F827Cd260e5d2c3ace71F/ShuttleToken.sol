// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;


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
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }


    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual returns (uint8) {
        return 18;
    }


    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }


    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }


    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }


    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {

                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {

                _totalSupply -= value;
            }
        } else {
            unchecked {

                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }


    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }


    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface Errors {
    error FeeIsAboveMaxFee(uint256 fee, uint256 maxFee);
    error AlreadyExcludedFromFee(address addr);
    error AlreadyIncludedInFee(address addr);
    error AddressIsZero();
    error AddressIsDead();
    error AlreadyLaunched(uint256 atBlockNumber);
    error BlockNumberToHigh();
    error NotStartedYet();
    error BlacklistedCannotTransfer();
    error AddressIsNotBlacklisted(address addr);
    error FeesMustBelowOrEqual10000();
    error MinimumTokensBeforeSwapHasToBeAbove10Ether();
    error SwapAndLiquifyAlreadyEnabled();
    error SwapAndLiquifyAlreadyDisabled();
    error AlreadyWhitelisted();
    error NotWhitelisted();
    error AddressCannotBeUnwhitelistedBecauseOfBalance();
}

interface Events {
    event BuyFeeUpdated(uint256 newFee, uint256 oldFee);
    event SellFeeUpdated(uint256 newFee, uint256 oldFee);
    event IsExcludedFromFee(address addr, bool flag);
    event BuyAndBurnWalletUpdated(address newAddress, address oldAddress);
    event ShuttleFundWalletUpdated(address newAddress, address oldAddress);
    event LaunchedAt(uint256 blockNumber);
    event AntiBlockNumberUpdated(uint256 blockNumber);
    event UnblacklistedAddress(address addr);
    event SwapTokensForETH(uint256 tokenAmount, address[] path);
    event PercentagesUpdated(uint256 shuttleFund, uint256 burnFee, uint256 tokensToEthFee);
    event MinimumTokensBeforeSwapUpdated(uint256 oldAmount, uint256 newAmount);
    event SwapAndLiquifyUpdated(bool isEnabled);
    event IsWhitelisted(address whitelistAddress, bool flag);
    event RouterAndPairUpdated(address router, address pair);
}

contract ShuttleToken is ERC20, Ownable, Errors, Events {
    struct Percentage {
        uint256 shuttleFund;
        uint256 burn;
        uint256 tokensToEth;
    }

    // Token
    string private constant _NAME = "Shuttle"; // Add here the name of the token
    string private constant _SYMBOL = "SHU"; // Add here the symbol of the token
    uint256 private constant _TOKENS_TO_MINT = 1_000_000_000; // Add here the amount of the tokens (without decimals, Decimals are set to 18 by default)
    uint256 private launchedAtBlock;

    // Addresses
    address public shuttleFundWallet = 0x7e622DE46f805518C71fd75067d5061e93EB79ba;
    address public buyAndBurnWallet = 0x15E712c275613b362Acf66AfeF779e0D62845656;
    /// @notice This is the wallet to transfer the funds
    /// @dev This wallet must be able to transfer tokens for the liquidity
    address public constant SHUTTLE_DEPLOY_WALLET = 0x782670F7c4Ef0c56141f9a496a465f5310F9b564;
    address private constant _PINKLOCK_ADDRESS = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE;
    address public pairAddress;
    IUniswapV2Router02 public router;
    mapping(address addr => bool isBlacklisted) public isBlacklisted;

    // Fees
    uint256 public buyFee = 5_00; // 5% (underscore for readability) e.g. 1% = 100, 0.5% = 50, 0.02% = 2
    uint256 public sellFee = 5_00; // 5%
    uint256 public antibotBlock;
    uint256 public constant MAX_FEE = 5_00; // Max 5%
    uint256 public constant FEE_DENOMINATOR = 100_00; // 100%
    uint256 public tokensBurnedTotal;
    uint256 public ethSentToBuyAndBurnWalletTotal;
    uint256 public tokensToBuyAndBurnWalletTotal;
    // Percentages for the buy/sell fee amount how much to distribute to shuttle wallet, burn and tokens to eth swap
    Percentage public percentages = Percentage({
        shuttleFund: 70_00,
        burn: 10_00,
        tokensToEth: 20_00
    });
    mapping(address addr => bool isExcluded) public isExcludedFromFee;
    mapping(address addr => bool isWhitelisted) public isWhitelisted;

    // Swap
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    uint256 public minimumTokensBeforeSwap = 10_000 ether;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address router_)
        ERC20(_NAME, _SYMBOL)
        Ownable(msg.sender)
    {
        _checkAddressIsNotZero(router_);
        router = IUniswapV2Router02(router_);
        pairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[shuttleFundWallet] = true;
        isExcludedFromFee[buyAndBurnWallet] = true;
        isExcludedFromFee[SHUTTLE_DEPLOY_WALLET] = true;
        isExcludedFromFee[_PINKLOCK_ADDRESS] = true;

        // Whitelistening addresses to transfer before launch
        isWhitelisted[msg.sender] = true;
        isWhitelisted[SHUTTLE_DEPLOY_WALLET] = true;
        isWhitelisted[pairAddress] = true;

        // Use of update for minting because of the "launched" property
        super._update(address(0), SHUTTLE_DEPLOY_WALLET, _TOKENS_TO_MINT * 10 ** decimals());
    }

    /// @notice Function to check the {fee_} is below or equal to {MAX_FEE}
    /// @param fee_ Fee to check
    function _checkFeeIsBelowOrEqualMaxFee(uint256 fee_) internal pure {
        if(fee_ > MAX_FEE)
            revert FeeIsAboveMaxFee(fee_, MAX_FEE);
    }

    /// @notice Function to check the {addr_} is not zero address
    /// @param addr_ Address to check
    function _checkAddressIsNotZero(address addr_) internal pure {
        if(addr_ == address(0x0))
            revert AddressIsZero();
    }

    /// @notice Function to check the {addr_} is not dead address
    /// @param addr_ Address to check
    function _checkAddressIsNotDead(address addr_) internal pure {
        if(addr_ == address(0xdead))
            revert AddressIsDead();
    }

    /// @notice Function to check the project is launched
    function _checkIsLaunched() internal view {
        if(_isLaunched())
            revert AlreadyLaunched(launchedAtBlock);
    }

    /// @notice Function is return true or false if the {launchedAtBlock} is 0 or not
    /// @return bool Whether the project is launched
    function _isLaunched() internal view returns(bool) {
        return launchedAtBlock != 0;
    }

    /// @notice Function to launch the project
    /// @dev Only the owner can launch the project
    function launch() external onlyOwner() {
        _checkIsLaunched();

        uint256 at = block.number;
        launchedAtBlock = at;
        swapAndLiquifyEnabled = true;

        emit LaunchedAt(at);
    }

    /// @notice Function to set the antibot block
    /// @dev Only the owner can launch the project. The {blockNumber_} must be set between 0 and 10 blocks.
    ///      The {antibotBlock} is 0 by default and can only be set when the project is not launched. In the function {_update}
    ///      the {launchedAtBlock} and {antibotBlock} are added and checked if the sum is below the current block number. If so, the caller
    ///      is set to {isBlacklisted} when selling. The owner can unblacklist the address manually.
    /// @param blockNumber_ The block number between 0-10
    function setAntibotBlock(uint256 blockNumber_) external onlyOwner() {
        _checkIsLaunched();
        if(blockNumber_ > 10)
            revert BlockNumberToHigh();

        antibotBlock = blockNumber_;

        emit AntiBlockNumberUpdated(blockNumber_);
    }

    /// @notice Unblacklist an address when it's blacklisted by selling below the antibot block number
    /// @dev The owner is able to unblacklist blacklisted addresses. It will be reverted when the address {addr_} is not blacklisted already.
    /// @param addr_ The address to unblacklist
    function unblacklist(address addr_) external onlyOwner() {
        if(!isBlacklisted[addr_])
            revert AddressIsNotBlacklisted(addr_);

        isBlacklisted[addr_] = false;

        emit UnblacklistedAddress(addr_);
    }

    /// @notice Set buy fee
    /// @dev Only the owner can set the fee. The {fee_} must be below or equal to the {MAX_FEE}
    /// @param fee_ The fee to set
    function setBuyFee(uint256 fee_) external onlyOwner() {
        _checkFeeIsBelowOrEqualMaxFee(fee_);

        uint256 oldFee = buyFee;
        buyFee = fee_;

        emit BuyFeeUpdated(fee_, oldFee);
    }

    /// @notice Set sell fee
    /// @dev Only the owner can set the fee. The {fee_} must be below or equal to the {MAX_FEE}
    /// @param fee_ The fee to set
    function setSellFee(uint256 fee_) external onlyOwner() {
        _checkFeeIsBelowOrEqualMaxFee(fee_);

        uint256 oldFee = sellFee;
        sellFee = fee_;

        emit SellFeeUpdated(fee_, oldFee);
    }

    /// @notice Whitelist an address to transfer before launch
    /// @dev The owner is able to whitelist addresses
    /// @param addr_ The address to whitelist
    function whitelist(address addr_) external onlyOwner() {
        if(isWhitelisted[addr_])
            revert AlreadyWhitelisted();

        isWhitelisted[addr_] = true;

        emit IsWhitelisted(addr_, true);
    }

    /// @notice UnWhitelist an address but only when the address has no balance
    /// @dev The owner is able to whitelist addresses
    /// @param addr_ The address to whitelist
    function unwhitelist(address addr_) external onlyOwner() {
        if(!isWhitelisted[addr_])
            revert NotWhitelisted();

        if(balanceOf(addr_) > 0)
            revert AddressCannotBeUnwhitelistedBecauseOfBalance();

        isWhitelisted[addr_] = false;

        emit IsWhitelisted(addr_, false);
    }

    /// @notice Function to exclude an address from the fees
    /// @dev Only owner can exclude addresses from the fees. Included addresses can be excluded only.
    /// @param addr_ The address to exclude from fees
    function excludeFromFee(address addr_) public onlyOwner() {
        if(isExcludedFromFee[addr_])
            revert AlreadyExcludedFromFee(addr_);

        isExcludedFromFee[addr_] = true;

        emit IsExcludedFromFee(addr_, true);
    }

    /// @notice Function to include an address to the fees
    /// @dev Only owner can include addresses back to the fees. Excluded addresses can be included only.
    /// @param addr_ The address to include to the fees
    function includeInFee(address addr_) external onlyOwner() {
        if(!isExcludedFromFee[addr_])
            revert AlreadyIncludedInFee(addr_);

        isExcludedFromFee[addr_] = false;
        emit IsExcludedFromFee(addr_, false);
    }

    /// @notice Set the percentages for the amount to distribute from the fees amount of the taken buy/sell
    /// @dev The fees must be below or equal to {FEE_DENOMINATOR}. Fees can be also 0.
    /// @param shuttleFundFee_ Percentage how much tokens should be distributed to the {shuttleFundWallet}
    /// @param burnFee_ Percentage how much tokens should be burned
    /// @param tokensToEthFee_ Percentage how much tokens should be distributed to the contract address.
    /// This will be swapped automatically after a specific condition.
    function setPercentages(uint256 shuttleFundFee_, uint256 burnFee_, uint256 tokensToEthFee_) external onlyOwner() {
        if(shuttleFundFee_ + burnFee_ + tokensToEthFee_ > FEE_DENOMINATOR)
            revert FeesMustBelowOrEqual10000();

        percentages = Percentage({
            shuttleFund: shuttleFundFee_,
            burn: burnFee_,
            tokensToEth: tokensToEthFee_
        });

        emit PercentagesUpdated(shuttleFundFee_, burnFee_, tokensToEthFee_);
    }

    /// @notice Updating the {buyAndBurnWallet}
    /// @dev The {buyAndBurnWallet} must be capable to receive ETH.
    /// @param addr_ New address for the {buyAndBurnWallet}
    function setBuyAndBurnWallet(address addr_) external onlyOwner() {
        _checkAddressIsNotZero(addr_);
        _checkAddressIsNotDead(addr_);

        address oldAddress = buyAndBurnWallet;
        buyAndBurnWallet = addr_;

        emit BuyAndBurnWalletUpdated(addr_, oldAddress);
    }

    /// @notice Updating the {shuttleFundWallet}
    /// @param addr_ New address for the {shuttleFundWallet}
    function setShuttleFundWallet(address addr_) external onlyOwner() {
        _checkAddressIsNotZero(addr_);
        _checkAddressIsNotDead(addr_);

        address oldAddress = shuttleFundWallet;
        shuttleFundWallet = addr_;

        emit ShuttleFundWalletUpdated(addr_, oldAddress);
    }

    /// @notice Overridden {_update} function from ERC20 contract
    /// @param from The sender address
    /// @param to The receiver address
    /// @param value The token amount
    function _update(address from, address to, uint256 value) internal override {
        if(!isWhitelisted[from] && !_isLaunched())
            revert NotStartedYet();

        if(isBlacklisted[from])
            revert BlacklistedCannotTransfer();

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        if (
            !inSwapAndLiquify &&
            from != pairAddress &&
            overMinimumTokenBalance &&
            swapAndLiquifyEnabled
        ) {
            _swapAndLiquify();
        }

        bool isBuy = from == pairAddress;
        bool isSell = to == pairAddress;

        uint256 currentFee = 0;
        if(isBuy && !isExcludedFromFee[to]) {
            currentFee = buyFee;
        } else if(isSell && !isExcludedFromFee[from]) {
            if(launchedAtBlock + antibotBlock > block.number) {
                isBlacklisted[from] = true;
                currentFee = 99_00;
            } else {
                currentFee = sellFee;
            }
        }

        // Update the value
        if(currentFee > 0) {
            value = _takeFee(value, currentFee);
        }
        super._update(from, to, value);
    }

    /// @notice Take fees function
    /// @dev Explain to a developer any extra details
    /// @param amount_ The sent amount
    /// @param feePercent_ The fee percentage for buy or sell
    /// @return The {amount_} minus the distributed fees
    function _takeFee(uint256 amount_, uint256 feePercent_) internal returns(uint256){
        uint256 tokenFeeAmount = amount_ * feePercent_ / FEE_DENOMINATOR;
        _distributeFees(tokenFeeAmount);

        return amount_ - tokenFeeAmount;
    }

    /// @notice Swap and liquify function
    function _swapAndLiquify() internal lockTheSwap {
        uint256 totalTokens = tokensToBuyAndBurnWalletTotal;
        // Reset tokens
        tokensToBuyAndBurnWalletTotal = 0;

        _swapTokensForEthToBuyAndBurnWallet(totalTokens);
    }

    /// @notice Manual Swap and liquify
    /// @dev Owner can swap manually
    function manualSwapAndLiquify() external onlyOwner() {
        _swapAndLiquify();
    }

    /// @notice Enable the swap and liquify functionality
    /// @dev Only owner can call this function. It will be reverted when it is enabled already.
    /// {swapAndLiquifyEnabled} is disabled by default.
    function enableSwapAndLiquify() external onlyOwner() {
        if(swapAndLiquifyEnabled)
            revert SwapAndLiquifyAlreadyEnabled();

        swapAndLiquifyEnabled = true;
        emit SwapAndLiquifyUpdated(true);
    }

    /// @notice Disable the swap and liquify functionality
    /// @dev Only owner can call this function. It will be reverted when it is disabled already.
    function disableSwapAndLiquify() external onlyOwner() {
        if(!swapAndLiquifyEnabled)
            revert SwapAndLiquifyAlreadyDisabled();

        swapAndLiquifyEnabled = false;
        emit SwapAndLiquifyUpdated(false);
    }

    /// @notice Set the minimum token amount before the swap should be executed
    /// @dev Only owner can call this function and the minimum should be 10 ether
    /// @param minimumTokensBeforeSwap_ The minimum amount before the swap should be executed
    function setMinimumTokenAmountBeforeSwap(uint256 minimumTokensBeforeSwap_) external onlyOwner() {
        if(minimumTokensBeforeSwap_ < 10_000 ether)
            revert MinimumTokensBeforeSwapHasToBeAbove10Ether();

        uint256 oldAmount = minimumTokensBeforeSwap;
        minimumTokensBeforeSwap = minimumTokensBeforeSwap_;

        emit MinimumTokensBeforeSwapUpdated(oldAmount, minimumTokensBeforeSwap_);
    }

    /// @notice Function to swap tokens to native tokens
    /// @param tokenAmount_ The token amount what should be swapped
    function _swapTokensForEthToBuyAndBurnWallet(uint256 tokenAmount_) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount_);

        uint256 initialBuyAndBurnWalletBalance = buyAndBurnWallet.balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount_,
            0, // accept any amount of ETH
            path,
            buyAndBurnWallet,
            block.timestamp
        );

        ethSentToBuyAndBurnWalletTotal += buyAndBurnWallet.balance - initialBuyAndBurnWalletBalance;

        emit SwapTokensForETH(tokenAmount_, path);
    }

    /// @notice Distribute fees function
    /// @dev When one of the percentages are 0 the part of the logic will be skipped. There is also
    ///      a fallback function because it is possible that there are a rest of tokens. When this occurs, the rest
    ///      will be transferred to the address of the fee's.
    /// @param tokenFeeAmount_ The token amount of the sell/buy fee token amount
    function _distributeFees(uint256 tokenFeeAmount_) internal {
        address from = msg.sender;
        Percentage memory percentages_ = percentages;

        // Shuttle fund wallet gets token
        uint256 shuttleFundWalletFeeAmount = 0;
        if(percentages_.shuttleFund > 0) {
            shuttleFundWalletFeeAmount = tokenFeeAmount_ * percentages_.shuttleFund / FEE_DENOMINATOR;
            super._update(from, shuttleFundWallet, shuttleFundWalletFeeAmount);
        }

        // Tokens will be burned
        uint256 buyAndBurnFeeAmount = 0;
        if(percentages_.burn > 0) {
            buyAndBurnFeeAmount = tokenFeeAmount_ * percentages_.burn / FEE_DENOMINATOR;
            // _burn(from, buyAndBurnFeeAmount);
            super._update(from, address(0), buyAndBurnFeeAmount);
            tokensBurnedTotal += buyAndBurnFeeAmount;
        }

        uint256 tokensToEthAmount = 0;
        if(percentages_.tokensToEth > 0) {
            tokensToEthAmount = tokenFeeAmount_ * percentages_.tokensToEth / FEE_DENOMINATOR;
            tokensToBuyAndBurnWalletTotal += tokensToEthAmount;
            super._update(from, address(this), tokensToEthAmount);
        }

        // Fallback when there is a little amount left add it to the contract
        uint256 totalFeeAmount = shuttleFundWalletFeeAmount + buyAndBurnFeeAmount + tokensToEthAmount;
        if(totalFeeAmount < tokenFeeAmount_) {
            uint256 leftTokens = tokenFeeAmount_ - totalFeeAmount;
            tokensToBuyAndBurnWalletTotal += leftTokens;
            super._update(from, address(this), leftTokens);
        }
    }

    /// @notice Updating the router and pair
    /// @dev If pair exists set it otherwise, create a new one. Only owner function. Can only be set when it is not launched
    /// @param router_ The new router address
    function updateRouterAddress(address router_) external onlyOwner() {
        _checkIsLaunched();
        router = IUniswapV2Router02(router_);
        address hasPair = IUniswapV2Factory(router.factory()).getPair(address(this), router.WETH());

        if(hasPair != address(0)) {
            pairAddress = hasPair;
        } else {
            pairAddress = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        }

        emit RouterAndPairUpdated(router_, pairAddress);
    }

    /// @notice Withdraw stuck tokens
    /// @dev Only callable by the owner. When there was accidentally sent own token to contract,
    ///      the owner can only transfer tokens that were not tracked. Other tokens from the fees
    ///      will not be transferred
    /// @param tokenAddress_ The token address from the stuck token. Pass address(0) to get
    ///        accidentally sent tokens from address(this) contract minus the tokens for the
    ///        {buyAndBurnWallet}
    function withdrawStuckTokens(address tokenAddress_) external onlyOwner() {
        _checkAddressIsNotDead(tokenAddress_);

        address contractAddress = address(this);
        uint256 tokenAmount;

        if(tokenAddress_ == address(0)) {
            tokenAmount = balanceOf(contractAddress);
            tokenAmount -= tokensToBuyAndBurnWalletTotal;

            if(tokenAmount > 0)
                super._update(contractAddress, msg.sender, tokenAmount);
        } else {
            IERC20 token = IERC20(tokenAddress_);
            tokenAmount = token.balanceOf(contractAddress);

            if(tokenAmount > 0)
                token.transfer(msg.sender, tokenAmount);
        }

    }
}