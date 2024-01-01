// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Accountant.sol";
import "./Transport.sol";
import "./IExecutor.sol";

import "./IVaultRiskProfile.sol";

import "./IntegrationDataTracker.sol";
import "./GmxConfig.sol";
import "./SnxConfig.sol";
import "./ILayerZeroEndpoint.sol";
import "./IAggregatorV3Interface.sol";
import "./IValioCustomAggregator.sol";

library RegistryStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.Registry');

    // Cannot use struct with diamond storage,
    // as adding any extra storage slots will break the following already declared members
    // solhint-disable-next-line ordering
    struct VaultSettings {
        bool ___deprecated;
        uint ____deprecated;
        uint _____deprecated;
        uint ______deprecated;
    }

    // solhint-disable-next-line ordering
    enum AssetType {
        None,
        GMX,
        Erc20,
        SnxPerpsV2
    }

    // solhint-disable-next-line ordering
    enum AggregatorType {
        ChainlinkV3USD,
        UniswapV3Twap,
        VelodromeV2Twap,
        None // Things like gmx return a value in usd so no aggregator is needed
    }

    // solhint-disable-next-line ordering
    struct Layout {
        uint16 chainId;
        address protocolTreasury;
        address parentVaultDiamond;
        address childVaultDiamond;
        mapping(address => bool) parentVaults;
        mapping(address => bool) childVaults;
        VaultSettings _deprecated;
        Accountant accountant;
        Transport transport;
        IntegrationDataTracker integrationDataTracker;
        GmxConfig gmxConfig;
        mapping(ExecutorIntegration => address) executors;
        // Price get will revert if the price hasn't be updated in the below time
        uint256 chainlinkTimeout;
        mapping(AssetType => address) valuers;
        mapping(AssetType => address) redeemers;
        mapping(address => AssetType) assetTypes;
        // All must return USD price and be 8 decimals
        mapping(address => IAggregatorV3Interface) chainlinkV3USDAggregators;
        mapping(address => bool) deprecatedAssets; // Assets that cannot be traded into, only out of
        address zeroXExchangeRouter;
        uint DEPRECATED_zeroXMaximumSingleSwapPriceImpactBips;
        bool canChangeManager;
        // The number of assets that can be active at once for a vault
        // This is important so withdraw processing doesn't consume > max gas
        uint maxActiveAssets;
        uint depositLockupTime;
        uint livelinessThreshold;
        mapping(VaultRiskProfile => uint) maxCpitBips;
        uint DEPRECATED_maxSingleActionImpactBips;
        uint minDepositAmount;
        bool canChangeManagerFees;
        // Assets that can be deposited into the vault
        mapping(address => bool) depositAssets;
        uint vaultValueCap;
        bool DEPRECATED_managerWhitelistEnabled;
        mapping(address => bool) DEPRECATED_allowedManagers;
        bool DEPRECATED_investorWhitelistEnabled;
        mapping(address => bool) DEPRECATED_allowedInvestors;
        address withdrawAutomator;
        mapping(address => IValioCustomAggregator) DEPRECATED_valioCustomUSDAggregators;
        address[] parentVaultList;
        address[] childVaultList;
        address[] assetList;
        uint maxDepositAmount;
        uint protocolFeeBips;
        mapping(address => AggregatorType) assetAggregatorType;
        // All must return USD price and be 8 decimals
        mapping(AggregatorType => IValioCustomAggregator) valioCustomUSDAggregators;
        address depositAutomator;
        SnxConfig snxConfig;
        address snxPerpsV2Erc20WrapperDiamond;
        mapping(address => uint) customVaultValueCaps;
        address[] snxPerpsV2Erc20WrapperList;
        // hardDeprecatedAssets Assets will return a value of 0
        // hardDeprecatedAssets Assets that cannot be traded into, only out of
        // A vault holding hardDeprecatedAssets will not be able be deposited into
        mapping(address => bool) hardDeprecatedAssets;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}
