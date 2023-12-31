// SPDX-License-Identifier: BUSL-1.1
// File: lib/ipor-protocol/contracts/libraries/errors/IporErrors.sol


pragma solidity 0.8.20;

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    /// @notice General problem, addresses mismatch
    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    /// @notice Value is not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    /// @notice Input arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    /// @notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    /// @notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    /// @notice only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    /// @notice Chunk size is equal to zero
    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    /// @notice Chunk size is too big
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    /// @notice Caller is not a  guardian
    string public constant CALLER_NOT_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @notice Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";

    /// @notice Caller is not an owner
    string public constant CALLER_NOT_OWNER = "IPOR_014";

    /// @notice Method is paused
    string public constant METHOD_PAUSED = "IPOR_015";

    /// @notice Reentrancy appears
    string public constant REENTRANCY = "IPOR_016";

    /// @notice Asset is not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

    /// @notice Return back ETH failed in Ipor Protocol Router
    string public constant ROUTER_RETURN_BACK_ETH_FAILED = "IPOR_018";
}

// File: lib/ipor-protocol/contracts/libraries/IporContractValidator.sol


pragma solidity 0.8.20;


library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }
}

// File: lib/ipor-protocol/contracts/interfaces/IStrategy.sol


pragma solidity 0.8.20;

/// @title Interface for interaction with  Asset Management's strategy.
/// @notice Strategy represents an external DeFi protocol and acts as and wrapper that standarizes the API of the external protocol.
interface IStrategy {
    /// @notice Returns current version of strategy
    /// @dev Increase number when implementation inside source code is different that implementation deployed on Mainnet
    /// @return current Strategy's version
    function getVersion() external pure returns (uint256);

    /// @notice Gets asset / underlying token / stablecoin which is assocciated with this Strategy instance
    /// @return asset / underlying token / stablecoin address
    function asset() external view returns (address);

    /// @notice Returns strategy's share token address
    function shareToken() external view returns (address);

    /// @notice Gets annualised interest rate (APR) for this strategy. Returns current APY from Dai Savings Rate.
    /// @return APR value, represented in 18 decimals.
    /// @dev APY = dsr^(365*24*60*60), dsr represented in 27 decimals
    function getApy() external view returns (uint256);

    /// @notice Gets balance for given asset (underlying / stablecoin) allocated to this strategy.
    /// @return balance for given asset, represented in 18 decimals.
    function balanceOf() external view returns (uint256);

    /// @notice Deposits asset amount from AssetManagement to this specific Strategy. Function available only for AssetManagement.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    function deposit(uint256 amount) external returns (uint256 depositedAmount);

    /// @notice Withdraws asset amount from Strategy to AssetManagement. Function available only for AssetManagement.
    /// @dev Emits {Transfer} from ERC20 asset. If available then events from external DeFi protocol assocciated with this strategy.
    /// @param amount asset amount represented in 18 decimals.
    /// @return withdrawnAmount The final amount withdrawn, represented in 18 decimals
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount);
}

// File: lib/ipor-protocol/contracts/interfaces/IAssetManagement.sol


pragma solidity 0.8.20;

/// @title Interface for interaction with Asset Management DSR smart contract.
/// @notice Asset Management is responsible for delegating assets stored in AmmTreasury to Asset Management and forward to money market where they can earn interest.
interface IAssetManagement {
    /// @notice Gets total balance of AmmTreasury, transferred assets to Asset Management.
    /// @return Total balance for specific account given as a parameter, represented in 18 decimals.
    function totalBalance() external view returns (uint256);

    /// @notice Deposits ERC20 underlying assets to AssetManagement. Function available only for AmmTreasury.
    /// @dev Emits {Deposit} event from AssetManagement, emits {Transfer} event from ERC20 asset.
    /// Input and output values are represented in 18 decimals.
    /// @param amount amount deposited by AmmTreasury to AssetManagement.
    /// @return vaultBalance current balance including amount deposited on AssteManagement.
    /// @return depositedAmount final deposited amount.
    function deposit(uint256 amount) external returns (uint256 vaultBalance, uint256 depositedAmount);

    /// @notice Withdraws declared amount of asset from AssetManagement to AmmTreasury. Function available only for AmmTreasury.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset.
    /// All input and output values are represented in 18 decimals.
    /// @param amount deposited amount of underlying asset represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of asset from AssetManagement, can be different than input amount due to passing time.
    /// @return vaultBalance current asset balance on AssetManagement
    function withdraw(uint256 amount) external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Withdraws all of the asset from AssetManagement to AmmTreasury. Function available only for AmmTreasury.
    /// @dev Emits {Withdraw} event from AssetManagement, emits {Transfer} event from ERC20 asset.
    /// Output values are represented in 18 decimals.
    /// @return withdrawnAmount final withdrawn amount of the asset.
    /// @return vaultBalance current asset's balance on AssetManagement
    function withdrawAll() external returns (uint256 withdrawnAmount, uint256 vaultBalance);

    /// @notice Emitted after AmmTreasury has executed deposit function.
    /// @param from account address from which assets are transferred
    /// @param to account address where assets are transferred to
    /// @param amount of asset transferred from AmmTreasury to AssetManagement, represented in 18 decimals
    event Deposit(address from, address to, uint256 amount);

    /// @notice Emitted when AmmTreasury executes withdraw function.
    /// @param to account address where assets are transferred to
    /// @param amount of asset transferred from AmmTreasury to AssetManagement, represented in 18 decimals
    event Withdraw(address to, uint256 amount);
}

// File: lib/ipor-protocol/contracts/interfaces/IAssetManagementLens.sol


pragma solidity 0.8.20;

/// @title AssetManagementLens interface responsible for reading data from AssetManagement.
interface IAssetManagementLens {
    /// @dev A struct to represent an asset configuration.
    struct AssetManagementConfiguration {
        /// @notice The address of the asset.
        address asset;
        /// @notice Asset decimals.
        uint256 decimals;
        /// @notice The address of the asset management contract.
        address assetManagement;
        /// @notice The address of the AMM treasury contract.
        address ammTreasury;
    }

    /// @notice Gets the AssetManagement configuration for the given asset.
    /// @param asset The address of the asset.
    /// @return AssetManagementConfiguration The AssetManagement configuration for the given asset.
    function getAssetManagementConfiguration(address asset) external view returns (AssetManagementConfiguration memory);

    /// @notice Gets balance of the AmmTreasury contract in the AssetManagement.
    /// @dev This includes assets transferred to AssetManagement.
    /// @param asset The address of the asset.
    /// @return uint256 The total balance for the specified account, represented in 18 decimals.
    function balanceOfAmmTreasuryInAssetManagement(address asset) external view returns (uint256);
}

// File: lib/ipor-protocol/contracts/amm/AssetManagementLens.sol


pragma solidity 0.8.20;






/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AssetManagementLens is IAssetManagementLens {
    using IporContractValidator for address;

    address internal immutable _usdt;
    uint256 internal immutable _usdtDecimals;
    address internal immutable _usdtAssetManagement;
    address internal immutable _usdtAmmTreasury;

    address internal immutable _usdc;
    uint256 internal immutable _usdcDecimals;
    address internal immutable _usdcAssetManagement;
    address internal immutable _usdcAmmTreasury;

    address internal immutable _dai;
    uint256 internal immutable _daiDecimals;
    address internal immutable _daiAssetManagement;
    address internal immutable _daiAmmTreasury;

    constructor(
        AssetManagementConfiguration memory usdtAssetManagementCfg,
        AssetManagementConfiguration memory usdcAssetManagementCfg,
        AssetManagementConfiguration memory daiAssetManagementCfg
    ) {
        _usdt = usdtAssetManagementCfg.asset.checkAddress();
        _usdtDecimals = usdtAssetManagementCfg.decimals;
        _usdtAssetManagement = usdtAssetManagementCfg.assetManagement.checkAddress();
        _usdtAmmTreasury = usdtAssetManagementCfg.ammTreasury.checkAddress();

        _usdc = usdcAssetManagementCfg.asset.checkAddress();
        _usdcDecimals = usdcAssetManagementCfg.decimals;
        _usdcAssetManagement = usdcAssetManagementCfg.assetManagement.checkAddress();
        _usdcAmmTreasury = usdcAssetManagementCfg.ammTreasury.checkAddress();

        _dai = daiAssetManagementCfg.asset.checkAddress();
        _daiDecimals = daiAssetManagementCfg.decimals;
        _daiAssetManagement = daiAssetManagementCfg.assetManagement.checkAddress();
        _daiAmmTreasury = daiAssetManagementCfg.ammTreasury.checkAddress();
    }

    function getAssetManagementConfiguration(
        address asset
    ) external view override returns (AssetManagementConfiguration memory) {
        return _getAssetManagementConfiguration(asset);
    }

    function balanceOfAmmTreasuryInAssetManagement(address asset) external view returns (uint256) {
        AssetManagementConfiguration memory assetManagementConfiguration = _getAssetManagementConfiguration(asset);
        return IAssetManagement(assetManagementConfiguration.assetManagement).totalBalance();
    }

    function _getAssetManagementConfiguration(
        address asset
    ) internal view returns (AssetManagementConfiguration memory) {
        if (asset == _usdt) {
            return
                AssetManagementConfiguration({
                    asset: _usdt,
                    decimals: _usdtDecimals,
                    assetManagement: _usdtAssetManagement,
                    ammTreasury: _usdtAmmTreasury
                });
        } else if (asset == _usdc) {
            return
                AssetManagementConfiguration({
                    asset: _usdc,
                    decimals: _usdcDecimals,
                    assetManagement: _usdcAssetManagement,
                    ammTreasury: _usdcAmmTreasury
                });
        } else if (asset == _dai) {
            return
                AssetManagementConfiguration({
                    asset: _dai,
                    decimals: _daiDecimals,
                    assetManagement: _daiAssetManagement,
                    ammTreasury: _daiAmmTreasury
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }
}