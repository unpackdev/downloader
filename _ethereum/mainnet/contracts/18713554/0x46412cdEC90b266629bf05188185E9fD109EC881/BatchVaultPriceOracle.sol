// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.4;
// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File libraries/Errors.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

/// @notice Defines different errors emitted by Gyroscope contracts
library Errors {
    string public constant TOKEN_AND_AMOUNTS_LENGTH_DIFFER = "1";
    string public constant TOO_MUCH_SLIPPAGE = "2";
    string public constant EXCHANGER_NOT_FOUND = "3";
    string public constant POOL_IDS_NOT_FOUND = "4";
    string public constant WOULD_UNBALANCE_GYROSCOPE = "5";
    string public constant VAULT_ALREADY_EXISTS = "6";
    string public constant VAULT_NOT_FOUND = "7";

    string public constant X_OUT_OF_BOUNDS = "20";
    string public constant Y_OUT_OF_BOUNDS = "21";
    string public constant PRODUCT_OUT_OF_BOUNDS = "22";
    string public constant INVALID_EXPONENT = "23";
    string public constant OUT_OF_BOUNDS = "24";
    string public constant ZERO_DIVISION = "25";
    string public constant ADD_OVERFLOW = "26";
    string public constant SUB_OVERFLOW = "27";
    string public constant MUL_OVERFLOW = "28";
    string public constant DIV_INTERNAL = "29";

    // User errors
    string public constant NOT_AUTHORIZED = "30";
    string public constant INVALID_ARGUMENT = "31";
    string public constant KEY_NOT_FOUND = "32";
    string public constant KEY_FROZEN = "33";
    string public constant INSUFFICIENT_BALANCE = "34";
    string public constant INVALID_ASSET = "35";
    string public constant FORBIDDEN_EXTERNAL_ACTION = "35";

    // Oracle related errors
    string public constant ASSET_NOT_SUPPORTED = "40";
    string public constant STALE_PRICE = "41";
    string public constant NEGATIVE_PRICE = "42";
    string public constant INVALID_MESSAGE = "43";
    string public constant TOO_MUCH_VOLATILITY = "44";
    string public constant WETH_ADDRESS_NOT_FIRST = "44";
    string public constant ROOT_PRICE_NOT_GROUNDED = "45";
    string public constant NOT_ENOUGH_TWAPS = "46";
    string public constant ZERO_PRICE_TWAP = "47";
    string public constant INVALID_NUMBER_WEIGHTS = "48";
    string public constant NO_WETH_PRICE = "49";

    //Vault safety check related errors
    string public constant A_VAULT_HAS_ALL_STABLECOINS_OFF_PEG = "51";
    string public constant NOT_SAFE_TO_MINT = "52";
    string public constant NOT_SAFE_TO_REDEEM = "53";
    string public constant AMOUNT_AND_PRICE_LENGTH_DIFFER = "54";
    string public constant TOKEN_PRICES_TOO_SMALL = "55";
    string public constant TRYING_TO_REDEEM_MORE_THAN_VAULT_CONTAINS = "56";
    string public constant CALLER_NOT_MOTHERBOARD = "57";
    string public constant CALLER_NOT_RESERVE_MANAGER = "58";
    string public constant VAULT_CANNOT_BE_REMOVED = "59";

    string public constant VAULT_FLOW_TOO_HIGH = "60";
    string public constant OPERATION_SUCCEEDS_BUT_SAFETY_MODE_ACTIVATED = "61";
    string public constant ORACLE_GUARDIAN_TIME_LIMIT = "62";
    string public constant NOT_ENOUGH_FLOW_DATA = "63";
    string public constant SUPPLY_CAP_EXCEEDED = "64";
    string public constant SAFETY_MODE_ACTIVATED = "65";

    // misc errors
    string public constant REDEEM_AMOUNT_BUG = "100";
    string public constant EXTERNAL_ACTION_FAILED = "101";
    string public constant TOKENS_NOT_SORTED = "102";
    string public constant NO_SHARES_MINTED = "103";
    string public constant TRYING_TO_REDEEM_MORE_THAN_SUPPLY = "104";
}


// File interfaces/IGovernable.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

interface IGovernable {
    /// @notice Emmited when the governor is changed
    event GovernorChanged(address oldGovernor, address newGovernor);

    /// @notice Emmited when the governor is change is requested
    event GovernorChangeRequested(address newGovernor);

    /// @notice Returns the current governor
    function governor() external view returns (address);

    /// @notice Returns the pending governor
    function pendingGovernor() external view returns (address);

    /// @notice Changes the governor
    /// can only be called by the current governor
    function changeGovernor(address newGovernor) external;

    /// @notice Called by the pending governor to approve the change
    function acceptGovernance() external;
}


// File contracts/auth/GovernableBase.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.


contract GovernableBase is IGovernable {
    address public override governor;
    address public override pendingGovernor;

    modifier governanceOnly() {
        require(msg.sender == governor, Errors.NOT_AUTHORIZED);
        _;
    }

    /// @inheritdoc IGovernable
    function changeGovernor(address newGovernor) external override governanceOnly {
        require(address(newGovernor) != address(0), Errors.INVALID_ARGUMENT);
        pendingGovernor = newGovernor;
        emit GovernorChangeRequested(newGovernor);
    }

    /// @inheritdoc IGovernable
    function acceptGovernance() external override {
        require(msg.sender == pendingGovernor, Errors.NOT_AUTHORIZED);
        address currentGovernor = governor;
        governor = pendingGovernor;
        pendingGovernor = address(0);
        emit GovernorChanged(currentGovernor, msg.sender);
    }
}


// File contracts/auth/Governable.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

contract Governable is GovernableBase {
    constructor(address _governor) {
        governor = _governor;
        emit GovernorChanged(address(0), _governor);
    }
}


// File libraries/DataTypes.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

/// @notice Contains the data structures to express token routing
library DataTypes {
    /// @notice Contains a token and the amount associated with it
    struct MonetaryAmount {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice Contains a token and the price associated with it
    /// @dev The price range is only relevant for stablecoins
    struct PricedToken {
        address tokenAddress;
        bool isStable;
        uint256 price;
        Range priceRange;
    }

    /// @notice A route from/to a token to a vault
    /// This is used to determine in which vault the token should be deposited
    /// or from which vault it should be withdrawn
    struct TokenToVaultMapping {
        address inputToken;
        address vault;
    }

    /// @notice Asset used to mint
    struct MintAsset {
        address inputToken;
        uint256 inputAmount;
        address destinationVault;
    }

    /// @notice Asset to redeem
    struct RedeemAsset {
        address outputToken;
        uint256 minOutputAmount;
        uint256 valueRatio;
        address originVault;
    }

    /// @notice Persisted metadata about the vault
    struct PersistedVaultMetadata {
        uint256 priceAtCalibration;
        uint256 weightAtCalibration;
        uint256 shortFlowMemory;
        uint256 shortFlowThreshold;
        uint64 weightTransitionDuration;
        uint64 weightAtPreviousCalibration;
        uint64 timeOfCalibration;
    }

    /// @notice Directional (in or out) flow data for the vaults
    struct DirectionalFlowData {
        uint128 shortFlow;
        uint64 lastSafetyBlock;
        uint64 lastSeenBlock;
    }

    /// @notice Bidirectional vault flow data
    struct FlowData {
        DirectionalFlowData inFlow;
        DirectionalFlowData outFlow;
    }

    /// @notice Vault flow direction
    enum Direction {
        In,
        Out,
        Both
    }

    /// @notice Vault address and direction for Oracle Guardian
    struct GuardedVaults {
        address vaultAddress;
        Direction direction;
    }

    /// @notice Vault with metadata
    struct VaultInfo {
        address vault;
        uint8 decimals;
        address underlying;
        uint256 price;
        PersistedVaultMetadata persistedMetadata;
        uint256 reserveBalance;
        uint256 currentWeight;
        uint256 targetWeight;
        PricedToken[] pricedTokens;
    }

    /// @notice Vault metadata
    struct VaultMetadata {
        address vault;
        uint256 targetWeight;
        uint256 currentWeight;
        uint256 resultingWeight;
        uint256 price;
        bool allStablecoinsOnPeg;
        bool atLeastOnePriceLargeEnough;
        bool vaultWithinEpsilon;
        PricedToken[] pricedTokens;
    }

    /// @notice Metadata to contain vaults metadata
    struct Metadata {
        VaultMetadata[] vaultMetadata;
        bool allVaultsWithinEpsilon;
        bool allStablecoinsAllVaultsOnPeg;
        bool allVaultsUsingLargeEnoughPrices;
        bool mint;
    }

    /// @notice Mint or redeem order struct
    struct Order {
        VaultWithAmount[] vaultsWithAmount;
        bool mint;
    }

    /// @notice Vault info with associated amount for order operation
    struct VaultWithAmount {
        VaultInfo vaultInfo;
        uint256 amount;
    }

    /// @notice state of the reserve (i.e., all the vaults)
    struct ReserveState {
        uint256 totalUSDValue;
        VaultInfo[] vaults;
    }

    struct VaultConfiguration {
        address vaultAddress;
        DataTypes.PersistedVaultMetadata metadata;
    }

    struct Range {
        uint256 floor;
        uint256 ceiling;
    }

    /// @notice Action executed by calling `target` passing in `data`
    struct ExternalAction {
        address target;
        bytes data;
    }
}


// File libraries/Arrays.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

library Arrays {
    /// @dev sorts in-place.
    function sort(address[] memory data) internal view returns (address[] memory) {
        if (data.length == 0) return data;
        _sort(data, int256(0), int256(data.length - 1));
        return data;
    }

    /// @dev Quicksort implementation
    function _sort(
        address[] memory arr,
        int256 left,
        int256 right
    ) internal view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        address pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _sort(arr, left, j);
        if (i < right) _sort(arr, i, right);
    }

    /// @dev Remove duplicates from a sorted array.
    function dedup(address[] memory data) internal pure returns (address[] memory) {
        uint256 duplicatedCount = 0;
        for (uint256 i = 1; i < data.length; i++) {
            if (data[i - 1] == data[i]) duplicatedCount++;
        }
        if (duplicatedCount == 0) return data;
        address[] memory deduped = new address[](data.length - duplicatedCount);
        for ((uint256 i, uint256 j) = (0, 0); i < data.length; i++) {
            if (i < data.length - 1 && data[i] == data[i + 1]) continue;
            deduped[j] = data[i];
            j++;
        }
        return deduped;
    }
}


// File libraries/Vaults.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

library Vaults {
    enum Type {
        GENERIC,
        BALANCER_CPMM,
        BALANCER_2CLP,
        BALANCER_3CLP,
        BALANCER_ECLP
    }
}


// File interfaces/oracles/IUSDBatchPriceOracle.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

interface IUSDBatchPriceOracle {
    /// @notice Quotes the USD price of `baseAssets`
    /// The quoted prices is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param baseAssets the assets of which the price is to be quoted
    /// @return the USD prices of the asset
    function getPricesUSD(address[] memory baseAssets) external view returns (uint256[] memory);
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.8.1

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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


// File @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol@v4.8.1

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol@v4.8.1

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol@v4.8.1

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)


/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File interfaces/oracles/IRateProvider.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

interface IRateProvider {
    function getRate() external view returns (uint256);
}


// File interfaces/IGyroVault.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.



/// @notice A vault is one of the component of the reserve and has a one-to-one
/// mapping to an underlying pool (e.g. Balancer pool, Curve pool, Uniswap pool...)
/// It is itself an ERC-20 token that is used to track the ownership of the LP tokens
/// deposited in the vault
/// A vault can be associated with a strategy to generate yield on the deposited funds
interface IGyroVault is IERC20MetadataUpgradeable, IERC20PermitUpgradeable, IRateProvider {
    /// @return The type of the vault
    function vaultType() external view returns (Vaults.Type);

    /// @return The token associated with this vault
    /// This can be any type of token but will likely be an LP token in practice
    function underlying() external view returns (address);

    /// @return The token associated with this vault
    /// In the case of an LP token, this will be the underlying tokens
    /// associated to it (e.g. [ETH, DAI] for a ETH/DAI pool LP token or [USDC] for aUSDC)
    /// In most cases, the tokens returned will not be LP tokens
    function getTokens() external view returns (IERC20[] memory);

    /// @return The total amount of underlying tokens in the vault
    function totalUnderlying() external view returns (uint256);

    /// @notice The same as getRate() from IRateProvider.
    /// @return The exchange rate between an underlying tokens and the token of this vault
    function exchangeRate() external view returns (uint256);

    /// @notice Deposits `underlyingAmount` of underlying (usually LP) token supported
    /// and sends back the received vault tokens
    /// @param underlyingAmount the amount of underlying to deposit
    /// @return vaultTokenAmount the amount of vault token sent back
    function deposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        returns (uint256 vaultTokenAmount);

    /// @notice Simlar to `deposit(uint256 underlyingAmount)` but credits the tokens
    /// to `beneficiary` instead of `msg.sender`
    function depositFor(
        address beneficiary,
        uint256 underlyingAmount,
        uint256 minVaultTokensOut
    ) external returns (uint256 vaultTokenAmount);

    /// @notice Dry-run version of deposit
    function dryDeposit(uint256 underlyingAmount, uint256 minVaultTokensOut)
        external
        view
        returns (uint256 vaultTokenAmount, string memory error);

    /// @notice Withdraws `vaultTokenAmount` of LP token supported
    /// and burns the vault tokens
    /// @param vaultTokenAmount the amount of vault token to withdraw
    /// @return underlyingAmount the amount of LP token sent back
    function withdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        returns (uint256 underlyingAmount);

    /// @notice Dry-run version of `withdraw`
    function dryWithdraw(uint256 vaultTokenAmount, uint256 minUnderlyingOut)
        external
        view
        returns (uint256 underlyingAmount, string memory error);

    /// @return The address of the current strategy used by the vault
    function strategy() external view returns (address);

    /// @notice Sets the address of the strategy to use for this vault
    /// This will be used through governance
    /// @param strategyAddress the address of the strategy contract that should follow the `IStrategy` interface
    function setStrategy(address strategyAddress) external;

    /// @return the block at which the vault has been deployed
    function deployedAt() external view returns (uint256);
}


// File interfaces/oracles/IVaultPriceOracle.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

interface IVaultPriceOracle {
    /// @notice Quotes the USD price of `vault` tokens
    /// The quoted price is always scaled with 18 decimals regardless of the
    /// source used for the oracle.
    /// @param vault the vault of which the price is to be quoted
    /// @return the USD price of the vault token
    function getPriceUSD(IGyroVault vault, DataTypes.PricedToken[] memory underlyingPricedTokens)
        external
        view
        returns (uint256);
}


// File interfaces/oracles/IBatchVaultPriceOracle.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.

interface IBatchVaultPriceOracle {
    event BatchPriceOracleChanged(address indexed priceOracle);
    event VaultPriceOracleChanged(Vaults.Type indexed vaultType, address indexed priceOracle);

    /// @notice Fetches the price of the vault token as well as the underlying tokens
    /// @return the same vaults info with the price data populated
    function fetchPricesUSD(
        DataTypes.VaultInfo[] memory vaultsInfo
    ) external view returns (DataTypes.VaultInfo[] memory);

    /// @notice Returns the price of the vault token give the prices included in `pricedTokens`
    function getVaultPrice(
        IGyroVault vault,
        DataTypes.PricedToken[] memory pricedTokens
    ) external view returns (uint256);
}


// File contracts/oracles/BatchVaultPriceOracle.sol

// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.





contract BatchVaultPriceOracle is IBatchVaultPriceOracle, Governable {
    using Arrays for address[];

    IUSDBatchPriceOracle public batchPriceOracle;

    mapping(Vaults.Type => IVaultPriceOracle) public vaultPriceOracles;

    constructor(address _governor, IUSDBatchPriceOracle _batchPriceOracle) Governable(_governor) {
        require(address(_batchPriceOracle) != address(0), Errors.INVALID_ARGUMENT);
        batchPriceOracle = _batchPriceOracle;
    }

    function setBatchPriceOracle(IUSDBatchPriceOracle priceOracle) external governanceOnly {
        batchPriceOracle = priceOracle;
        emit BatchPriceOracleChanged(address(priceOracle));
    }

    function registerVaultPriceOracle(Vaults.Type vaultType, IVaultPriceOracle priceOracle)
        external
        governanceOnly
    {
        vaultPriceOracles[vaultType] = priceOracle;
        emit VaultPriceOracleChanged(vaultType, address(priceOracle));
    }

    function fetchPricesUSD(DataTypes.VaultInfo[] memory vaultsInfo)
        external
        view
        returns (DataTypes.VaultInfo[] memory)
    {
        address[] memory tokens = _constructTokensArray(vaultsInfo);
        uint256[] memory underlyingPrices = batchPriceOracle.getPricesUSD(tokens);

        for (uint256 i = 0; i < vaultsInfo.length; i++) {
            _assignUnderlyingTokenPrices(vaultsInfo[i], tokens, underlyingPrices);
            vaultsInfo[i].price = getVaultPrice(
                IGyroVault(vaultsInfo[i].vault),
                vaultsInfo[i].pricedTokens
            );
        }

        return vaultsInfo;
    }

    function getVaultPrice(IGyroVault vault, DataTypes.PricedToken[] memory pricedTokens)
        public
        view
        returns (uint256)
    {
        IVaultPriceOracle vaultPriceOracle = vaultPriceOracles[vault.vaultType()];
        require(address(vaultPriceOracle) != address(0), Errors.ASSET_NOT_SUPPORTED);
        return vaultPriceOracle.getPriceUSD(vault, pricedTokens);
    }

    function _assignUnderlyingTokenPrices(
        DataTypes.VaultInfo memory vaultInfo,
        address[] memory tokens,
        uint256[] memory underlyingPrices
    ) internal pure {
        for ((uint256 i, uint256 j) = (0, 0); i < vaultInfo.pricedTokens.length; i++) {
            // Here we make use of the fact that both vaultInfo.pricedTokens and tokens are sorted by
            // token address, so we don't have to reset j.
            while (tokens[j] != vaultInfo.pricedTokens[i].tokenAddress) j++;
            vaultInfo.pricedTokens[i].price = underlyingPrices[j];
        }
    }

    function _constructTokensArray(DataTypes.VaultInfo[] memory vaultsInfo)
        internal
        view
        returns (address[] memory)
    {
        uint256 tokensCount = 0;
        for (uint256 i = 0; i < vaultsInfo.length; i++) {
            tokensCount += vaultsInfo[i].pricedTokens.length;
        }
        address[] memory tokens = new address[](tokensCount);
        for ((uint256 i, uint256 k) = (0, 0); i < vaultsInfo.length; i++) {
            for (uint256 j = 0; j < vaultsInfo[i].pricedTokens.length; (j++, k++)) {
                tokens[k] = vaultsInfo[i].pricedTokens[j].tokenAddress;
            }
        }
        return tokens.sort().dedup();
    }
}