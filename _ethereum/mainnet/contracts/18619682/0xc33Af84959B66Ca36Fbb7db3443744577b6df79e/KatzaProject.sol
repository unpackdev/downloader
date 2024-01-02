// File: interfaces/IUniswapV2Factory.sol


pragma solidity ^0.8.0;

// only necessary functions
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// File: interfaces/IUniswapV2Router02.sol


pragma solidity ^0.8.0;

// only necessary functions
interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}

// File: interfaces/IERC20SwapTax.sol


pragma solidity ^0.8.20;

//
// === fees ===
// Generally, taxes on tokens are used for either
//   1) paying the team
//   2) revenue share
//   3) adding to liquidity
// So i decided to give deployers these three options. Project also occasionally
// burn tokens from taxes, but I didn't feel that was essential functionality.
//
// === limits and blacklists ===
// Due to the nature of the token's reliance on the v2Router and its own liquidity,
// it's natural that contract owners might want more granular control over
// actions that could potentially harm the LP. The contract gives owners the option
// to activate:
//   - limits on maxTransaction sizes and maxWallet sizes
//   - blacklist that restricts swaps and transfers
//

/// @title ERC20 Swap Tax Interface
/// @notice An ERC20 Swap Tax token takes a fee from all token swaps
interface IERC20SwapTax {

    // immutables

    /// @notice The main v2 router address
    function v2Router() external view returns (address);
    /// @notice The main v2 pair address
    function v2Pair() external view returns (address);
    /// @notice The initial token supply
    function initialSupply() external view returns (uint256);

    // fees

    /// @notice The total tax taken on swaps in percent
    function totalSwapFee() external view returns (uint8);
    /// @notice The protocol tax allocation in percent
    function protocolFee() external view returns (uint8);
    /// @notice The liquidity pool tax allocation in percent
    function liquidityFee() external view returns (uint8);
    /// @notice The team tax allocation in percent
    function teamFee() external view returns (uint8);
    /// @notice The address to collect the team fee
    function teamWallet() external view returns (address);
    /// @notice The address to collect the protocol fee
    function protocolWallet() external view returns (address);

    // params

    /// @notice The minimum amount of token that the contract will swap
    function swapThreshold() external view returns (uint128);
    /// @notice The maximum amount of token that the contract will swap
    function maxContractSwap() external view returns (uint128);
    /// @notice If limits are active, the max swap amount
    function maxTransaction() external view returns (uint128);
    /// @notice If limits are active, the max wallet size
    function maxWallet() external view returns (uint128);

    // state

    /// @notice If limits are active
    function limitsActive() external view returns (bool);
    /// @notice If the blacklist is active
    function blacklistActive() external view returns (bool);
    /// @notice If trading through the v2Pair is enabled
    function tradingEnabled() external view returns (bool);
    /// @notice If the contract is allowed to swap
    function contractSwapEnabled() external view returns (bool);

    // addresses

    /// @notice Is the address an automated market-maker pair
    function isAmm(address) external view returns (bool);
    /// @notice Is the address excluded from tax fees
    function isExcludedFromFees(address) external view returns (bool);
    /// @notice Is the address blacklisted
    function isBlacklisted(address) external view returns (bool);
    /// @notice Is the address excluded from limits
    function isExcludedFromLimits(address) external view returns (bool);

    // events
    event AmmUpdated(address indexed account, bool isAmm);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event TeamWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event ProtocolWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event SwapAndAdd(uint256 tokensSwapped, uint256 ethToLp, uint256 tokenToLp);
}

// File: dependencies/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: dependencies/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: interfaces/IERC20Permit.sol


pragma solidity ^0.8.0;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: dependencies/ERC20.sol


pragma solidity >=0.8.0;



// Same as Solmate ERC20 with a virtual internal _transfer()

/// @title Lightweight ERC20
/// @notice A gas-efficient ERC20Permit contract
/// @dev Ensure to always update totalSupply with balance
abstract contract ERC20 is IERC20, IERC20Permit {
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);

        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// File: libraries/Math.sol


pragma solidity ^0.8.20;

// helpful pure math functions
library Math {
    uint256 internal constant MAX_UINT256 = 2 ** 256 - 1;

    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }
}

// File: katza_x.sol



// Katza Project.
// https://t.me/katzaproject
// https://twitter.com/katzaproject
// https://katza.world

pragma solidity ^0.8.20;







contract KatzaProject is ERC20, IERC20SwapTax, Ownable {
    using Math for uint256;

    function MAX_TAX() public pure virtual returns (uint8) {
        return 5;
    }

    uint256 public immutable override initialSupply;

    address public immutable override v2Router;
    address public immutable override v2Pair;

    address public override protocolWallet;
    address public override teamWallet;

    bool public override tradingEnabled;
    bool public override contractSwapEnabled;

    bool public override limitsActive;
    bool public override blacklistActive;

    uint8 public override totalSwapFee;
    uint8 public override protocolFee;
    uint8 public override liquidityFee;
    uint8 public override teamFee;

    mapping(address => bool) public override isAmm;
    mapping(address => bool) public override isBlacklisted;
    mapping(address => bool) public override isExcludedFromFees;
    mapping(address => bool) public override isExcludedFromLimits;

    uint128 public override swapThreshold;
    uint128 public override maxContractSwap;
    uint128 public override maxTransaction;
    uint128 public override maxWallet;

    bool private _swapping;
    address internal immutable WETH;
    address internal constant DEAD = address(0xdEaD);

    receive() external payable {}

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _v2Router,
        address _protocolWallet,
        uint8 _protocolFee,
        uint8 _liquidityFee,
        uint8 _teamFee,
        bool _limitsActive,
        bool _blacklistActive
    ) ERC20(_name, _symbol, 18) {
        initialSupply = _initialSupply;

        protocolWallet = _protocolWallet;
        teamWallet = owner();

        limitsActive = _limitsActive;
        blacklistActive = _blacklistActive;

        updateFees(_protocolFee, _liquidityFee, _teamFee);

        v2Router = _v2Router;
        WETH = IUniswapV2Router02(v2Router).WETH();
        v2Pair = IUniswapV2Factory(IUniswapV2Router02(v2Router).factory()).createPair(address(this), WETH);

    
        swapThreshold   = uint128(initialSupply.mulDiv(25  , 10_000));
        maxContractSwap = uint128(initialSupply.mulDiv(50 , 10_000));
        maxTransaction  = uint128(initialSupply.mulDiv(500, 10_000));
        maxWallet       = uint128(initialSupply.mulDiv(500, 10_000));

        updateAmm(v2Pair, true);

        excludeFromLimits(address(this), true);
        excludeFromLimits(owner(), true);
        excludeFromLimits(v2Router, true);
        excludeFromLimits(v2Pair, true);
        excludeFromLimits(DEAD, true);

        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);
        excludeFromFees(DEAD, true);

        allowance[address(this)][v2Router] = type(uint256).max;
        emit Approval(address(this), v2Router, type(uint256).max);

        _mint(owner(), initialSupply);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (blacklistActive) require(!(isBlacklisted[from] || isBlacklisted[to]), "BL");
        if (limitsActive) _checkLimits(from, to, amount);

        bool excluded = isExcludedFromFees[from] || isExcludedFromFees[to];
        uint8 _swapFee = totalSwapFee;

        if (excluded || _swapFee == 0 || amount == 0) {
            // no fees or excluded -> process transfer normally
            super._transfer(from, to, amount);
            return;
        }

        // if currently swapping exclude from all fees
        excluded = _swapping;

        bool isBuy = isAmm[from];

        if (isBuy || excluded || !contractSwapEnabled || balanceOf[address(this)] < swapThreshold) {
            // ...
        } else {
            _swapping = true;
            _swapBack();
            _swapping = false;
        }


        balanceOf[from] -= amount;
        uint256 fee = 0;

        if ((isBuy || isAmm[to]) && !excluded) {
            fee = amount.mulDiv(_swapFee, 100);

            unchecked {
                balanceOf[address(this)] += fee;
            }
            emit Transfer(from, address(this), fee);
        }

        unchecked {
            balanceOf[to] += (amount - fee);
        }
        emit Transfer(from, to, amount - fee);
    }

    function _checkLimits(address from, address to, uint256 amount) internal view {
        if (from == owner() || to == owner() || to == DEAD || _swapping) return;

        if (!tradingEnabled) {
            require(isExcludedFromFees[from] || isExcludedFromFees[to], "TC");
        }
        // buy
        if (isAmm[from] && !isExcludedFromLimits[to]) {
            require(amount <= maxTransaction, "MAX_TX");
            require(amount + balanceOf[to] <= maxWallet, "MAX_WALLET");
        }
        // sell
        else if (isAmm[to] && !isExcludedFromLimits[from]) {
            require(amount <= maxTransaction, "MAX_TX");
        }
        // transfer
        else if (!isExcludedFromLimits[to]) {
            require(amount + balanceOf[to] <= maxWallet, "MAX_WALLET");
        }
    }

    /// @dev Swap contract balance to ETH if over the threshold
    function _swapBack() private {
        uint256 balance = balanceOf[address(this)];

        if (balance == 0) return;
        if (balance > maxContractSwap) balance = maxContractSwap;

        uint256 protocolTokens = balance.mulDiv(protocolFee, totalSwapFee);
        uint256 teamTokens = balance.mulDiv(teamFee, totalSwapFee);

        // half the remaining tokens are for liquidity
        uint256 liquidityTokens = (balance - protocolTokens - teamTokens) / 2;
        uint256 swapTokens = balance - liquidityTokens;

        uint256 ethBalance = address(this).balance;

        _swapTokensForEth(swapTokens);

        ethBalance = address(this).balance - ethBalance;

        uint256 ethForTeam = ethBalance.mulDiv(teamTokens, swapTokens);
        uint256 ethForLiquidity = ethBalance - ethForTeam - ethBalance.mulDiv(protocolTokens, swapTokens);

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);

            emit SwapAndAdd(swapTokens, ethForLiquidity, liquidityTokens);
        }

        // don't verify the call so transfers out can fail
        (bool success, ) = teamWallet.call{value: ethForTeam}("");
        (success, ) = protocolWallet.call{value: address(this).balance}("");
    }

    /// @dev Perform a v2 swap for ETH
    function _swapTokensForEth(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        IUniswapV2Router02(v2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add v2 liquidity
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        IUniswapV2Router02(v2Router).addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    /// @dev Once trading is active, can never be inactive
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        contractSwapEnabled = true;
    }

    /// @dev Update the threshold for contract swaps
    function updateSwapThreshold(uint128 newThreshold) external onlyOwner {
        require(newThreshold >= totalSupply.mulDiv(1, 1_000_000), "BST"); // >= 0.0001%
        require(newThreshold <= totalSupply.mulDiv(5, 10_000), "BST"); // <= 0.05%
        swapThreshold = newThreshold;
    }

    /// @dev Update the max contract swap
    function updateMaxContractSwap(uint128 newMaxSwap) external onlyOwner {
        require(newMaxSwap >= totalSupply.mulDiv(1, 100_000), "BMS"); // >= 0.001%
        require(newMaxSwap <= totalSupply.mulDiv(50, 10_000), "BMS"); // <= 0.5%
        maxContractSwap = newMaxSwap;
    }

    /// @dev Update the max transaction while limits are in effect
    function updateMaxTransaction(uint128 newMaxTx) external onlyOwner {
        require(newMaxTx >= totalSupply.mulDiv(50, 10_000), "BMT"); // >= 0.5%
        maxTransaction = newMaxTx;
    }

    /// @dev Update the max wallet while limits are in effect
    function updateMaxWallet(uint128 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= totalSupply.mulDiv(100, 10_000), "BMW"); // >= 1%
        maxWallet = newMaxWallet;
    }

    /// @dev Emergency disabling of contract sales
    function updateContractSwapEnabled(bool enabled) external onlyOwner {
        contractSwapEnabled = enabled;
    }

    /// @dev Update the swap fees
    function updateFees(uint8 _protocolFee, uint8 _liquidityFee, uint8 _teamFee) public onlyOwner {
        require(_protocolFee + _liquidityFee + _teamFee <= MAX_TAX(), "BF");
        totalSwapFee = _protocolFee + _liquidityFee + _teamFee;
        protocolFee = _protocolFee;
        liquidityFee = _liquidityFee;
        teamFee = _teamFee;
    }

    /// @dev Exclude account from the limited max transaction size
    function excludeFromLimits(address account, bool excluded) public onlyOwner {
        isExcludedFromLimits[account] = excluded;
    }

    /// @dev Exclude account from all fees
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    /// @dev Designate address as an AMM pair to process fees
    function updateAmm(address account, bool amm) public onlyOwner {
        if (!amm) require(account != v2Pair, "FP");
        isAmm[account] = amm;
        emit AmmUpdated(account, amm);
    }

    /// @dev Update the protocol wallet
    function updateProtocolWallet(address newWallet) external onlyOwner {
        emit ProtocolWalletUpdated(newWallet, protocolWallet);
        protocolWallet = newWallet;
    }

    /// @dev Update the team wallet
    function updateTeamWallet(address newWallet) external onlyOwner {
        emit TeamWalletUpdated(newWallet, teamWallet);
        teamWallet = newWallet;
    }

    /// @dev Withdraw token stuck in the contract
    function sweepToken(address token, address to) external onlyOwner {
        require(token != address(0), "ZA");
        ERC20(token).transfer(to, ERC20(token).balanceOf(address(this)));
    }

    /// @dev Withdraw eth stuck in the contract
    function sweepEth(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "TF");
    }

    /// @dev Blacklist an account
    function blacklist(address account) public onlyOwner {
        require(blacklistActive, "RK");
        require(account != address(v2Pair), "BLU");
        require(account != address(v2Router), "BLU");
        isBlacklisted[account] = true;
    }

    /// @dev Remove an account from the blacklist
    function unblacklist(address account) public onlyOwner {
        isBlacklisted[account] = false;
    }

    /// @dev Irreversible action, limits can never be reinstated
    function deactivateLimits() external onlyOwner {
        limitsActive = false;
    }

    /// @dev Renounce blacklist authority
    function deactivateBlacklist() public onlyOwner {
        blacklistActive = false;
    }
}