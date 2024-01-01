// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File src/base/Multicall.sol

uint256 constant NUM_STABLE_COINS = 2;

pragma solidity 0.8.13;

/// @title  Multicall
/// @author Uniswap Labs
///
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall {
    error MulticallFailed(bytes data, bytes result);

    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; ++i) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                revert MulticallFailed(data[i], result);
            }

            results[i] = result;
        }
    }
}


// File src/base/ErrorMessages.sol

pragma solidity >=0.8.4;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgument(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalState(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperation(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error Unauthorized(string message);


// File src/base/MutexLock.sol

pragma solidity 0.8.13;

/// @title  Mutex
/// @author Alchemix Finance
///
/// @notice Provides a mutual exclusion lock for implementing contracts.
abstract contract MutexLock {
    enum State {
        RESERVED,
        UNLOCKED,
        LOCKED
    }

    /// @notice The lock state.
    State private _lockState = State.UNLOCKED;

    /// @dev A modifier which acquires the mutex.
    modifier lock() {
        _claimLock();

        _;

        _freeLock();
    }

    /// @dev Gets if the mutex is locked.
    ///
    /// @return if the mutex is locked.
    function _isLocked() internal view returns (bool) {
        return _lockState == State.LOCKED;
    }

    /// @dev Claims the lock. If the lock is already claimed, then this will revert.
    function _claimLock() internal {
        // Check that the lock has not been claimed yet.
        if (_lockState != State.UNLOCKED) {
            revert IllegalState("Lock already claimed");
        }

        // Claim the lock.
        _lockState = State.LOCKED;
    }

    /// @dev Frees the lock.
    function _freeLock() internal {
        _lockState = State.UNLOCKED;
    }
}


// File src/interfaces/IERC20Metadata.sol

pragma solidity >=0.5.0;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}


// File lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File src/libraries/SafeERC20.sol

pragma solidity >=0.8.4;

/// @title  SafeERC20
/// @author Alchemix Finance
library SafeERC20 {
    /// @notice An error used to indicate that a call to an ERC20 contract failed.
    ///
    /// @param target  The target address.
    /// @param success If the call to the token was a success.
    /// @param data    The resulting data from the call. This is error data when the call was not a
    ///                success. Otherwise, this is malformed data when the call was a success.
    error ERC20CallFailed(address target, bool success, bytes data);

    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an
    ///      unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (!success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an
    ///      unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an
    ///      unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an
    ///      unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(address token, address owner, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, owner, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }
}


// File src/interfaces/IERC20TokenReceiver.sol

pragma solidity >=0.5.0;

/// @title  IERC20TokenReceiver
/// @author Alchemix Finance
interface IERC20TokenReceiver {
    /// @notice Informs implementors of this interface that an ERC20 token has been transferred.
    ///
    /// @param token The token that was transferred.
    /// @param value The amount of the token that was transferred.
    function onERC20Received(address token, uint256 value) external;
}


// File src/interfaces/external/convex/IConvexStakingWrapper.sol

pragma solidity >=0.5.0;

interface IConvexStakingWrapper {
    function deposit(uint256 amount, address to) external;
    function withdraw(uint256 amount) external;
    function withdrawAndUnwrap(uint256 _amount) external;
}


// File src/interfaces/external/curve/IStableSwap2Pool.sol

pragma solidity >=0.5.0;

uint256 constant N_COINS = 2;

interface IStableSwap2Pool {
    function coins(uint256 index) external view returns (address);

    function A() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(
        uint256[N_COINS] calldata amounts,
        bool deposit
    ) external view returns (uint256 amount);

    function add_liquidity(uint256[N_COINS] calldata amounts, uint256 minimumMintAmount) external;

    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256 dy);

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256 dy);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minimumDy
    ) external payable returns (uint256);

    function remove_liquidity(uint256 amount, uint256[N_COINS] calldata minimumAmounts, address receiver) external returns (uint256[] memory);

    function remove_liquidity_imbalance(
        uint256[N_COINS] calldata amounts,
        uint256 maximumBurnAmount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 tokenAmount,
        int128 i,
        uint256 minimumAmount
    ) external;
}


// File src/interfaces/external/convex/IConvexFraxFarm.sol

pragma solidity >=0.5.0;

interface IConvexFraxFarm {
    function withdrawLocked(bytes32 kek_id, address destination_address)  external returns (uint256);
    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32);
    function earned(address account) external view returns (uint256[] memory);
    function getReward(address destination_address) external returns (uint256[] memory);
    function combinedWeightOf(address account) external view returns (uint256);
    function lockedLiquidityOf(address account) external view returns (uint256);
}


// File src/interfaces/external/convex/IConvexFraxVault.sol

pragma solidity >=0.5.0;

interface IConvexFraxVault {
    function stakeLockedCurveLp(uint256 liquidity, uint256 secs) external returns (bytes32 kekId);
    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32 kekId);
    function withdrawLockedAndUnwrap(bytes32 kekId) external;
    function getReward() external;
    function earned() external view returns (address[] memory tokenAddresses, uint256[] memory totalEarned);
}


// File src/interfaces/external/convex/IConvexRewards.sol

pragma solidity >=0.5.0;

interface IConvexRewards {
    function rewardToken() external view returns (IERC20);
    function earned(address account) external view returns (uint256);
    function extraRewards(uint256 index) external view returns (address);
    function balanceOf(address account) external returns(uint256);
    function withdraw(uint256 amount, bool claim) external returns (bool);
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
    function getReward() external returns (bool);
    function getReward(address recipient, bool claim) external returns (bool);
    function stake(uint256 amount) external returns (bool);
    function stakeFor(address account, uint256 amount) external returns (bool);
}


// File src/interfaces/external/convex/IConvexFraxBooster.sol

pragma solidity >=0.5.0;

interface IConvexFraxBooster {
    function createVault(uint256 _pid) external returns (address);
}


// File src/interfaces/external/convex/IConvexToken.sol

pragma solidity >=0.5.0;

interface IConvexToken is IERC20 {
    function maxSupply() external view returns (uint256);
    function totalCliffs() external view returns (uint256);
    function reductionPerCliff() external view returns (uint256);
}


// File src/PoolAssetManager.sol

pragma solidity 0.8.13;









/// @notice A struct used to define initialization parameters. This is not included
///         in the contract to prevent naming collisions.
struct InitializationParams {
    address admin;
    address operator;
    address rewardReceiver;
    address transmuterBuffer;
    IERC20 fraxShareToken;
    IERC20 curveToken;
    IStableSwap2Pool twoPool;
    uint256 twoPoolSlippage;
    IConvexToken convexToken;
    IConvexStakingWrapper convexStakingWrapper;
    IConvexFraxBooster convexFraxBooster;
    uint256 convexPoolId;
}

struct LockParams {
    uint256 amount;
    uint256 timeLocked;
}

/// @dev The amount of precision that slippage parameters have.
uint256 constant SLIPPAGE_PRECISION = 1e4;

/// @dev The amount of precision that curve pools use for price calculations.
uint256 constant CURVE_PRECISION = 1e18;

uint256 constant MINIMUM_LOCK_TIME = 604800;

/// @notice Enumerations for FRAX/USDC two pool assets.
///
/// @dev Do not change the order of these fields.
enum PoolAsset {
    ALETH, FRXETH
}

/// @title  PoolAssetManager
/// @author Alchemix Finance
contract PoolAssetManager is Multicall, MutexLock, IERC20TokenReceiver {
    /// @notice Emitted when the admin is updated.
    ///
    /// @param admin The admin.
    event AdminUpdated(address admin);

    /// @notice Emitted when the pending admin is updated.
    ///
    /// @param pendingAdmin The pending admin.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the operator is updated.
    ///
    /// @param operator The operator.
    event OperatorUpdated(address operator);

    /// @notice Emitted when the reward receiver is updated.
    ///
    /// @param rewardReceiver The reward receiver.
    event RewardReceiverUpdated(address rewardReceiver);

    /// @notice Emitted when the transmuter buffer is updated.
    ///
    /// @param transmuterBuffer The transmuter buffer.
    event TransmuterBufferUpdated(address transmuterBuffer);

    /// @notice Emitted when the 2pool slippage is updated.
    ///
    /// @param twoPoolSlippage The 2pool slippage.
    event TwoPoolSlippageUpdated(uint256 twoPoolSlippage);

    /// @notice Emitted when 2pool tokens are minted.
    ///
    /// @param amounts               The amounts of each 2pool asset used to mint liquidity.
    /// @param mintedTwoPoolTokens The amount of 2pool tokens minted.
    event MintTwoPoolTokens(uint256[NUM_STABLE_COINS] amounts, uint256 mintedTwoPoolTokens);

    /// @notice Emitted when 2pool tokens are minted.
    ///
    /// @param asset                 The 2pool asset used to mint 2pool tokens.
    /// @param amount                The amount of the asset used to mint 2pool tokens.
    /// @param mintedTwoPoolTokens The amount of 2pool tokens minted.
    event MintTwoPoolTokens(PoolAsset asset, uint256 amount, uint256 mintedTwoPoolTokens);

    /// @notice Emitted when 2pool tokens are burned.
    ///
    /// @param asset     The 2pool asset that was received.
    /// @param amount    The amount of 2pool tokens that were burned.
    /// @param withdrawn The amount of the 2pool asset that was withdrawn.
    event BurnTwoPoolTokens(PoolAsset asset, uint256 amount, uint256 withdrawn);

    /// @notice Emitted when meta pool tokens are deposited into convex.
    ///
    /// @param amount  The amount of meta pool tokens that were deposited.
    /// @param id      The ID of the new lock.
    /// @param success If the operation was successful.
    event DepositTwoPoolTokens(uint256 amount, bytes32 id, bool success);

    /// @notice Emitted when meta pool tokens are withdrawn from convex.
    ///
    /// @param amount  The amount of meta pool tokens that were withdrawn.
    /// @param success If the operation was successful.
    event WithdrawTwoPoolTokens(uint256 amount, bool success);

    /// @notice Emitted when convex rewards are claimed.
    ///
    /// @param success      If the operation was successful.
    /// @param amountFxs    The amount of frax share tokens sent to the reward recipient.
    /// @param amountCurve  The amount of curve tokens sent to the reward recipient.
    /// @param amountConvex The amount of convex tokens sent to the reward recipient.
    event ClaimRewards(bool success, uint256 amountFxs, uint256 amountCurve, uint256 amountConvex);

    /// @notice Emitted when 2pool assets are sent to the transmuter buffer.
    ///
    /// @param asset  The 2pool asset that was reclaimed.
    /// @param amount The amount of the asset that was reclaimed.
    event ReclaimTwoPoolAsset(PoolAsset asset, uint256 amount);

    /// @notice The admin.
    address public admin;

    /// @notice The current pending admin.
    address public pendingAdmin;

    /// @notice The operators.
    mapping(address => bool) public operators;

    // @notice The reward receiver.
    address public rewardReceiver;

    /// @notice The transmuter buffer.
    address public transmuterBuffer;

    /// @notice The frax share token.
    IERC20 public immutable fraxShareToken;

    /// @notice The curve token.
    IERC20 public immutable curveToken;

    /// @notice The 2pool contract.
    IStableSwap2Pool public immutable twoPool;

    /// @notice The amount of slippage that will be tolerated when depositing and withdrawing assets
    ///         from the stable swap pool. In units of basis points.
    uint256 public twoPoolSlippage;

    /// @notice The convex token.
    IConvexToken public immutable convexToken;

    /// @notice The staking wrapper.
    IConvexStakingWrapper public immutable convexStakingWrapper;

    /// @notice The convex booster contract.
    IConvexFraxBooster public immutable convexFraxBooster;

    /// @notice The address of the vault created during the contructor.
    IConvexFraxVault public convexFraxVault;

    /// @notice The convex pool identifier.
    uint256 public immutable convexPoolId;

    /// @notice the kek_id of the twoPool token deposit.
    mapping (bytes32 => LockParams) public kekId;

    /// @dev A cache of the tokens that the stable swap pool supports.
    IERC20[NUM_STABLE_COINS] private _twoPoolAssetCache;

    /// @dev A modifier which reverts if the message sender is not the admin.
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert Unauthorized("Not admin");
        }
        _;
    }

    /// @dev A modifier which reverts if the message sender is not the operator.
    modifier onlyOperator() {
        if (!operators[msg.sender]) {
            revert Unauthorized("Not operator");
        }
        _;
    }

    constructor(InitializationParams memory params) {
        admin                   = params.admin;
        rewardReceiver          = params.rewardReceiver;
        transmuterBuffer        = params.transmuterBuffer;
        fraxShareToken          = params.fraxShareToken;
        curveToken              = params.curveToken;
        twoPool                 = params.twoPool;
        twoPoolSlippage         = params.twoPoolSlippage;
        convexToken             = params.convexToken;
        convexStakingWrapper    = params.convexStakingWrapper;
        convexFraxBooster       = params.convexFraxBooster;
        convexPoolId            = params.convexPoolId;

        operators[params.operator] = true;

        convexFraxVault = IConvexFraxVault(convexFraxBooster.createVault(convexPoolId));

        for (uint256 i = 0; i < NUM_STABLE_COINS; i++) {
            _twoPoolAssetCache[i] = IERC20(params.twoPool.coins(i));
        }

        emit AdminUpdated(admin);
        emit OperatorUpdated(params.operator);
        emit RewardReceiverUpdated(rewardReceiver);
        emit TransmuterBufferUpdated(transmuterBuffer);
        emit TwoPoolSlippageUpdated(twoPoolSlippage);
    }

    /// @notice Gets the amount of a 2pool asset that this contract has in reserves.
    ///
    /// @param asset The 2pool asset.
    ///
    /// @return The reserves.
    function twoPoolAssetReserves(PoolAsset asset) external view returns (uint256) {
        IERC20 token = getTokenForTwoPoolAsset(asset);
        return token.balanceOf(address(this));
    }

    /// @notice Gets the amount of a 2pool asset that one alUSD is worth.
    ///
    /// @param asset The 2pool asset.
    ///
    /// @return The amount of the underying.
    function exchangeRate(PoolAsset asset) public view returns (uint256) {
        return twoPool.calc_withdraw_one_coin(1e18, int128(uint128(uint256(asset))));
    }

    /// @notice Gets the ERC20 token associated with a 2pool asset.
    ///
    /// @param asset The asset to get the token for.
    ///
    /// @return The token.
    function getTokenForTwoPoolAsset(PoolAsset asset) public view returns (IERC20) {
        uint256 index = uint256(asset);
        if (index >= NUM_STABLE_COINS) {
            revert IllegalArgument("Asset index out of bounds");
        }
        return _twoPoolAssetCache[index];
    }

    /// @notice Begins the 2-step process of setting the administrator.
    ///
    /// The caller must be the admin. Setting the pending timelock to the zero address will stop
    /// the process of setting a new timelock.
    ///
    /// @param value The value to set the pending timelock to.
    function setPendingAdmin(address value) external onlyAdmin {
        pendingAdmin = value;
        emit PendingAdminUpdated(value);
    }

    /// @notice Completes the 2-step process of setting the administrator.
    ///
    /// The pending admin must be set and the caller must be the pending admin. After this function
    /// is successfully executed, the admin will be set to the pending admin and the pending admin
    /// will be reset.
    function acceptAdmin() external {
        if (pendingAdmin == address(0)) {
            revert IllegalState("Pending admin unset");
        }

        if (pendingAdmin != msg.sender) {
            revert Unauthorized("Not pending admin");
        }

        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit AdminUpdated(admin);
        emit PendingAdminUpdated(address(0));
    }

    /// @notice Sets the operator.
    ///
    /// The caller must be the admin.
    ///
    /// @param operator The address to set
    /// @param value The value to set the admin to.
    function setOperator(address operator, bool value) external onlyAdmin {
        operators[operator] = value;
        emit OperatorUpdated(operator);
    }

    /// @notice Sets the reward receiver.
    ///
    /// @param value The value to set the reward receiver to.
    function setRewardReceiver(address value) external onlyAdmin {
        rewardReceiver = value;
        emit RewardReceiverUpdated(value);
    }

    /// @notice Sets the transmuter buffer.
    ///
    /// @param value The value to set the transmuter buffer to.
    function setTransmuterBuffer(address value) external onlyAdmin {
        transmuterBuffer = value;
        emit TransmuterBufferUpdated(value);
    }

    /// @notice Sets the slippage that will be tolerated when depositing and withdrawing 2pool
    ///         assets. The slippage has a resolution of 6 decimals.
    ///
    /// The operator is allowed to set the slippage because it is a volatile parameter that may need
    /// fine adjustment in a short time window.
    ///
    /// @param value The value to set the slippage to.
    function setTwoPoolSlippage(uint256 value) external onlyOperator {
        if (value > SLIPPAGE_PRECISION) {
            revert IllegalArgument("Slippage not in range");
        }
        twoPoolSlippage = value;
        emit TwoPoolSlippageUpdated(value);
    }

    /// @notice Mints 2pool tokens with a combination of assets.
    ///
    /// @param amounts The amounts of the assets to deposit.
    ///
    /// @return minted The number of 2pool tokens minted.
    function mintTwoPoolTokens(
        uint256[NUM_STABLE_COINS] calldata amounts
    ) external lock onlyOperator returns (uint256 minted) {
        return _mintTwoPoolTokens(amounts);
    }

    /// @notice Mints 2pool tokens with an asset.
    ///
    /// @param asset  The asset to deposit into the 2pool.
    /// @param amount The amount of the asset to deposit.
    ///
    /// @return minted The number of 2pool tokens minted.
    function mintTwoPoolTokens(
        PoolAsset asset,
        uint256 amount
    ) external lock onlyOperator returns (uint256 minted) {
        return _mintTwoPoolTokens(asset, amount);
    }

    /// @notice Burns 2pool tokens to withdraw an asset.
    ///
    /// @param asset  The asset to withdraw.
    /// @param amount The amount of 2pool tokens to burn.
    ///
    /// @return withdrawn The amount of the asset withdrawn from the pool.
    function burnTwoPoolTokens(
        PoolAsset asset,
        uint256 amount
    ) external lock onlyOperator returns (uint256 withdrawn) {
        return _burnTwoPoolTokens(asset, amount);
    }

    /// @notice Deposits and stakes meta pool tokens into convex.
    ///
    /// @param amount The amount of meta pool tokens to deposit.
    ///
    /// @return success If the tokens were successfully deposited.
    /// @return id      The ID of the new lock.
    function depositTwoPoolTokens(
        uint256 amount
    ) external lock onlyOperator returns (bool success, bytes32 id) {
        return _depositTwoPoolTokens(amount, MINIMUM_LOCK_TIME);
    }

    /// @notice Deposits and stakes meta pool tokens into convex.
    ///
    /// @param amount The amount of meta pool tokens to deposit.
    ///
    /// @return success If the tokens were successfully deposited.
    /// @return id      The ID of the new lock.
    function depositTwoPoolTokensCustomLock(
        uint256 amount,
        uint256 lockTime
    ) external lock onlyOperator returns (bool success, bytes32 id) {
        return _depositTwoPoolTokens(amount, lockTime);
    }

    /// @notice Withdraws and unwraps meta pool tokens from convex.
    ///
    /// @param  amount  The amount of meta pool tokens to withdraw.
    /// @param  id      The id of the lock to withdraw from.  
    ///
    /// @return success If the tokens were successfully withdrawn.
    function withdrawTwoPoolTokens(
        uint256 amount,
        bytes32 id
    ) external lock onlyOperator returns (bool success) {
        return _withdrawTwoPoolTokens(amount, id);
    }

    /// @notice Claims convex, curve, and auxiliary rewards.
    ///
    /// @return success If the claim was successful.
    function claimRewards() external lock onlyOperator returns (bool success) {
        convexFraxVault.getReward();
        success = true;

        uint256 fxsBalance    = fraxShareToken.balanceOf(address(this));
        uint256 curveBalance  = curveToken.balanceOf(address(this));
        uint256 convexBalance = convexToken.balanceOf(address(this));

        SafeERC20.safeTransfer(address(curveToken), rewardReceiver, curveBalance);
        SafeERC20.safeTransfer(address(convexToken), rewardReceiver, convexBalance);
        SafeERC20.safeTransfer(address(fraxShareToken), rewardReceiver, fxsBalance);

        emit ClaimRewards(success, fxsBalance, curveBalance, convexBalance);
    }

    /// @notice Flushes two pool assets into convex by minting 2pool tokens from the assets,
    ///         minting meta pool tokens using the 2pool tokens, and then depositing the meta pool
    ///         tokens into convex.
    ///
    /// This function is provided for ease of use.
    ///
    /// @param amounts The amounts of the 2pool assets to flush.
    ///
    /// @return The amount of meta pool tokens deposited into convex.
    function flush(
        uint256[NUM_STABLE_COINS] calldata amounts
    ) external lock onlyOperator returns (uint256) {
        uint256 mintedTwoPoolTokens = _mintTwoPoolTokens(amounts);

        (bool success,) = _depositTwoPoolTokens(mintedTwoPoolTokens, MINIMUM_LOCK_TIME);

        if (!success) {
            revert IllegalState("Deposit into convex failed");
        }

        return mintedTwoPoolTokens;
    }

    /// @notice Flushes two pool assets into convex by minting 2pool tokens from the assets,
    ///         minting meta pool tokens using the 2pool tokens, and then depositing the meta pool
    ///         tokens into convex. Allows specification of locking period.
    ///
    /// This function is provided for ease of use.
    ///
    /// @param amounts The amounts of the 2pool assets to flush.
    /// @param lockTime The amount of time to lock the staked tokens.
    ///
    /// @return The amount of meta pool tokens deposited into convex.
    function flushCustomLock(
        uint256[NUM_STABLE_COINS] calldata amounts,
        uint256 lockTime
    ) external lock onlyOperator returns (uint256) {
        uint256 mintedTwoPoolTokens = _mintTwoPoolTokens(amounts);

        (bool success, ) = _depositTwoPoolTokens(mintedTwoPoolTokens, lockTime);

        if (!success) {
            revert IllegalState("Deposit into convex failed");
        }

        return mintedTwoPoolTokens;
    }

    /// @notice Flushes a two pool asset into convex by minting 2pool tokens using the asset,
    ///         minting meta pool tokens using the 2pool tokens, and then depositing the meta pool
    ///         tokens into convex.
    ///
    /// This function is provided for ease of use.
    ///
    /// @param asset  The 2pool asset to flush.
    /// @param amount The amount of the 2pool asset to flush.
    ///
    /// @return The amount of meta pool tokens deposited into convex.
    function flush(
        PoolAsset asset,
        uint256 amount
    ) external lock onlyOperator returns (uint256) {
        uint256 mintedTwoPoolTokens = _mintTwoPoolTokens(asset, amount);

        (bool success,) = _depositTwoPoolTokens(mintedTwoPoolTokens, MINIMUM_LOCK_TIME);

        if (!success) {
            revert IllegalState("Deposit into convex failed");
        }

        return mintedTwoPoolTokens;
    }

    /// @notice Flushes a two pool asset into convex by minting 2pool tokens using the asset,
    ///         minting meta pool tokens using the 2pool tokens, and then depositing the meta pool
    ///         tokens into convex. Allows specification of locking period.
    ///
    /// This function is provided for ease of use.
    ///
    /// @param asset    The 2pool asset to flush.
    /// @param amount   The amount of the 2pool asset to flush.
    /// @param lockTime The amount of time to lock the staked tokens.
    ///
    /// @return The amount of meta pool tokens deposited into convex.
    function flushCustomLock(
        PoolAsset asset,
        uint256 amount,
        uint256 lockTime
    ) external lock onlyOperator returns (uint256) {
        uint256 mintedTwoPoolTokens = _mintTwoPoolTokens(asset, amount);

        (bool success, bytes32 id) = _depositTwoPoolTokens(mintedTwoPoolTokens, lockTime);

        if (!success) {
            revert IllegalState("Deposit into convex failed");
        }

        return mintedTwoPoolTokens;
    }

    /// @notice Recalls a two pool asset into reserves by withdrawing meta pool tokens from
    ///         convex, burning the meta pool tokens for 2pool tokens, and then burning the 2pool
    ///         tokens for an asset.
    ///
    /// This function is provided for ease of use.
    ///
    /// @param asset  The 2pool asset to recall.
    /// @param amount The amount of the meta pool tokens to withdraw from convex and burn.
    /// @param  id      The id of the lock to withdraw from.  
    ///
    /// @return The amount of the 2pool asset recalled.
    function recall(
        PoolAsset asset,
        uint256 amount,
        bytes32 id
    ) external lock onlyOperator returns (uint256) {

        if (!_withdrawTwoPoolTokens(amount, id)) {
            revert IllegalState("Withdraw from convex failed");
        }
        return _burnTwoPoolTokens(asset, amount);
    }

    /// @notice Recalls tokens in a balanced manner in case of an emergency
    function emergencyRecall(uint256 amount, bytes32 id) external lock onlyOperator {
        if (!_withdrawTwoPoolTokens(amount, id)) {
            revert IllegalState("Withdraw from convex failed");
        }        

        IERC20 twoPoolToken = IERC20(address(twoPool));

        SafeERC20.safeApprove(address(twoPoolToken), address(twoPool), 0);
        SafeERC20.safeApprove(address(twoPoolToken), address(twoPool), amount);

        // Remove the liquidity from the pool.
        uint256[2] memory minAmounts = [uint256(0), uint256(0)];
        twoPool.remove_liquidity(amount, minAmounts, address(this));
    }

    /// @notice Reclaims a two pool asset to the transmuter buffer.
    ///
    /// @param asset  The 2pool asset to reclaim.
    /// @param amount The amount to reclaim.
    function reclaimTwoPoolAsset(PoolAsset asset, uint256 amount) public lock onlyAdmin {
        IERC20 token = getTokenForTwoPoolAsset(asset);
        SafeERC20.safeTransfer(address(token), transmuterBuffer, amount);

        IERC20TokenReceiver(transmuterBuffer).onERC20Received(address(token), amount);

        emit ReclaimTwoPoolAsset(asset, amount);
    }

    /// @notice Sweeps a token out of the contract to the admin.
    ///
    /// @param token  The token to sweep.
    /// @param amount The amount of the token to sweep.
    function sweep(address token, uint256 amount) external lock onlyAdmin {
        SafeERC20.safeTransfer(address(token), msg.sender, amount);
    }

    /// @inheritdoc IERC20TokenReceiver
    ///
    /// @dev This function is required in order to receive tokens from the conduit.
    function onERC20Received(address token, uint256 value) external { /* noop */ }

    /// @dev Mints 2pool tokens with a combination of assets.
    ///
    /// @param amounts The amounts of the assets to deposit.
    ///
    /// @return minted The number of 2pool tokens minted.
    function _mintTwoPoolTokens(
        uint256[NUM_STABLE_COINS] calldata amounts
    ) internal returns (uint256 minted) {
        IERC20[NUM_STABLE_COINS] memory tokens = _twoPoolAssetCache;

        IERC20 twoPoolToken = IERC20(address(twoPool));

        uint256 twoPoolDecimals = SafeERC20.expectDecimals(address(twoPoolToken));
        uint256 normalizedTotal   = 0;

        for (uint256 i = 0; i < NUM_STABLE_COINS; i++) {
            if (amounts[i] == 0) continue;

            uint256 tokenDecimals   = SafeERC20.expectDecimals(address(tokens[i]));
            uint256 missingDecimals = twoPoolDecimals - tokenDecimals;

            normalizedTotal += amounts[i] * 10**missingDecimals;

            // For assets like USDT, the approval must be first set to zero before updating it.
            SafeERC20.safeApprove(address(tokens[i]), address(twoPool), 0);
            SafeERC20.safeApprove(address(tokens[i]), address(twoPool), amounts[i]);
        }

        // Calculate what the normalized value of the tokens is.
        uint256 expectedOutput = normalizedTotal * CURVE_PRECISION / twoPool.get_virtual_price();

        // Calculate the minimum amount of 2pool lp tokens that we are expecting out when
        // adding liquidity for all of the assets. This value is twod off the optimistic
        // assumption that one of each token is approximately equal to one 2pool lp token.
        uint256 minimumMintAmount = expectedOutput * twoPoolSlippage / SLIPPAGE_PRECISION;

        // Record the amount of 2pool lp tokens that we start with before adding liquidity
        // so that we can determine how many we minted.
        uint256 startingBalance = twoPoolToken.balanceOf(address(this));

        // Add the liquidity to the pool.
        twoPool.add_liquidity(amounts, minimumMintAmount);

        // Calculate how many 2pool lp tokens were minted.
        minted = twoPoolToken.balanceOf(address(this)) - startingBalance;

        emit MintTwoPoolTokens(amounts, minted);
    }

    /// @dev Mints 2pool tokens with an asset.
    ///
    /// @param asset  The asset to deposit into the 2pool.
    /// @param amount The amount of the asset to deposit.
    ///
    /// @return minted The number of 2pool tokens minted.
    function _mintTwoPoolTokens(
        PoolAsset asset,
        uint256 amount
    ) internal returns (uint256 minted) {
        IERC20 token          = getTokenForTwoPoolAsset(asset);
        IERC20 twoPoolToken = IERC20(address(twoPool));

        uint256 twoPoolDecimals = SafeERC20.expectDecimals(address(twoPoolToken));
        uint256 missingDecimals   = twoPoolDecimals - SafeERC20.expectDecimals(address(token));

        uint256[NUM_STABLE_COINS] memory amounts;
        amounts[uint256(asset)] = amount;

        // Calculate the minimum amount of 2pool lp tokens that we are expecting out when
        // adding single sided liquidity. This value is twod off the optimistic assumption that
        // one of each token is approximately equal to one 2pool lp token.
        uint256 expectedOutput    = amount * CURVE_PRECISION / twoPool.get_virtual_price();
        uint256 minimumMintAmount = expectedOutput * twoPoolSlippage / SLIPPAGE_PRECISION;

        // Record the amount of 2pool lp tokens that we start with before adding liquidity
        // so that we can determine how many we minted.
        uint256 startingBalance = twoPoolToken.balanceOf(address(this));

        // For assets like USDT, the approval must be first set to zero before updating it.
        SafeERC20.safeApprove(address(token), address(twoPool), 0);
        SafeERC20.safeApprove(address(token), address(twoPool), amount);

        // Add the liquidity to the pool.
        twoPool.add_liquidity(amounts, minimumMintAmount);

        // Calculate how many 2pool lp tokens were minted.
        minted = twoPoolToken.balanceOf(address(this)) - startingBalance;

        emit MintTwoPoolTokens(asset, amount, minted);
    }

    /// @dev Burns 2pool tokens to withdraw an asset.
    ///
    /// @param asset  The asset to withdraw.
    /// @param amount The amount of 2pool tokens to burn.
    ///
    /// @return withdrawn The amount of the asset withdrawn from the pool.
    function _burnTwoPoolTokens(
        PoolAsset asset,
        uint256 amount
    ) internal returns (uint256 withdrawn) {
        IERC20 token          = getTokenForTwoPoolAsset(asset);
        IERC20 twoPoolToken = IERC20(address(twoPool));

        uint256 index = uint256(asset);

        // Calculate the minimum amount of underlying tokens that we are expecting out when
        // removing single sided liquidity. This value is twod off the optimistic assumption that
        // one of each token is approximately equal to one 2pool lp token.
        uint256 normalizedAmount = amount * twoPoolSlippage / SLIPPAGE_PRECISION;
        uint256 minimumAmountOut   = normalizedAmount * twoPool.get_virtual_price() / CURVE_PRECISION;

        // Record the amount of underlying tokens that we start with before removing liquidity
        // so that we can determine how many we withdrew from the pool.
        uint256 startingBalance = token.balanceOf(address(this));

        SafeERC20.safeApprove(address(twoPoolToken), address(twoPool), 0);
        SafeERC20.safeApprove(address(twoPoolToken), address(twoPool), amount);

        // Remove the liquidity from the pool.
        twoPool.remove_liquidity_one_coin(amount, int128(uint128(index)), minimumAmountOut);

        // Calculate how many underlying tokens that were withdrawn.
        withdrawn = token.balanceOf(address(this)) - startingBalance;

        emit BurnTwoPoolTokens(asset, amount, withdrawn);
    }

    // /// @dev Burns 2pool tokens to withdraw an asset.
    // ///
    // /// @param amount The amount of 2pool tokens to burn.
    // function _burnTwoPoolTokensBalanced(
    //     uint256 amount,
    //     uint256[2] calldata minAmounts
    // ) internal {
    //     IERC20 twoPoolToken = IERC20(address(twoPool));

    //     SafeERC20.safeApprove(address(twoPoolToken), address(twoPool), 0);
    //     SafeERC20.safeApprove(address(twoPoolToken), address(twoPool), amount);

    //     // Remove the liquidity from the pool.
    //     twoPool.remove_liquidity(amount, minAmounts, address(this));
    // }

    /// @dev Deposits and stakes meta pool tokens into convex.
    ///
    /// @param amount   The amount of meta pool tokens to deposit.
    /// @param lockTime The time of the new lock.
    ///
    /// @return success If the tokens were successfully deposited.
    /// @return id      The id of the new lock.
    function _depositTwoPoolTokens(uint256 amount, uint256 lockTime) internal returns (bool success, bytes32 id) {
        SafeERC20.safeApprove(address(twoPool), address(convexFraxVault), amount);
        id = convexFraxVault.stakeLockedCurveLp(amount, lockTime);
        kekId[id] = LockParams({amount: amount, timeLocked: lockTime});

        success = true;

        emit DepositTwoPoolTokens(amount, id, success);
    }

    /// @dev Withdraws and unwraps meta pool tokens from convex.
    ///
    /// @param amount   The amount of meta pool tokens to withdraw.
    /// @param id       The id of the lock you wish to withdraw from.
    ///
    /// @return success If the tokens were successfully withdrawn.
    function _withdrawTwoPoolTokens(uint256 amount, bytes32 id) internal returns (bool success) {
        uint256 originalBalance = IERC20(address(twoPool)).balanceOf(address(this));

        convexFraxVault.withdrawLockedAndUnwrap(id);

        uint256 newBalance = IERC20(address(twoPool)).balanceOf(address(this));

        // Frax vaults require to withdraw all meta tokens.
        // We must re-stake any remaining tokens.
        uint256 restakeAmount = newBalance - originalBalance - amount;

        if (restakeAmount > 1) {
            SafeERC20.safeApprove(address(twoPool), address(convexFraxVault), restakeAmount);
            bytes32 newId = convexFraxVault.stakeLockedCurveLp(restakeAmount, MINIMUM_LOCK_TIME);
            kekId[newId] = LockParams({amount: restakeAmount, timeLocked: MINIMUM_LOCK_TIME});
            emit DepositTwoPoolTokens(restakeAmount, newId, success);
        }

        success = true;
        emit WithdrawTwoPoolTokens(IERC20(address(twoPool)).balanceOf(address(this)), success);
    }

    /// @dev Claims convex, curve, and auxiliary rewards.
    ///
    /// @return success If the claim was successful.
    function _claimRewards() internal returns (bool) {
        convexFraxVault.getReward();

        uint256 fxsBalance    = fraxShareToken.balanceOf(address(this));
        uint256 curveBalance  = curveToken.balanceOf(address(this));
        uint256 convexBalance = convexToken.balanceOf(address(this));

        SafeERC20.safeTransfer(address(curveToken), rewardReceiver, curveBalance);
        SafeERC20.safeTransfer(address(convexToken), rewardReceiver, convexBalance);
        
        emit ClaimRewards(true, fxsBalance, curveBalance, convexBalance);

        return true;
    }

    /// @dev Gets the minimum of two integers.
    ///
    /// @param x The first integer.
    /// @param y The second integer.
    ///
    /// @return The minimum value.
    function min(uint256 x , uint256 y) private pure returns (uint256) {
        return x > y ? y : x;
    }

    /// @dev Gets the absolute value of the difference of two integers.
    ///
    /// @param x The first integer.
    /// @param y The second integer.
    ///
    /// @return The absolute value.
    function abs(uint256 x , uint256 y) private pure returns (uint256) {
        return x > y ? x - y : y - x;
    }
}