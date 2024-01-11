// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "Ownable.sol";
import {IResolverV2} from "IResolverV2.sol";
import {IVaultMK2} from "IVaultMK2.sol";
import {IStrategyAPI} from "IStrategyAPI.sol";
import {IVaultAPI} from "IVaultAPI.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs

// Primary Author(s)
// Farhaan Ali: https://github.com/farhaan-ali

// Reviewer(s) / Contributor(s)
// Kristian Domanski: https://github.com/kristian-gro

/// @title Gelato Harvest Resolver
/// @notice To work with Gelato Ops to automate strategy harvests
contract HarvestResolverV2 is IResolverV2, Ownable {
    /*///////////////////////////////////////////////////////////////
                    Storage Variables/Types/Modifier(s)
    //////////////////////////////////////////////////////////////*/
    /// @notice Struct holding relevant strategy params
    struct strategyParams {
        uint256 gasUsed;
        bool canHarvest;
        address _address;
        uint256 acceptableLoss;
    }
    /// @notice address for DAI Vault
    address public immutable DAIVAULT;
    /// @notice address for USDC Vault
    address public immutable USDCVAULT;
    /// @notice address for USDT Vault
    address public immutable USDTVAULT;
    /// @notice Nested mapping of (strategy index => strategy params)
    mapping(address => mapping(uint256 => strategyParams)) public strategyInfo;
    /// @notice max base fee we accept for a harvest
    uint256 public maxBaseFee;
    /// @notice modifier to check vault address passed is a gro vault
    modifier onlyGroVault(address vaultAddress) {
        require(
            vaultAddress == DAIVAULT ||
                vaultAddress == USDCVAULT ||
                vaultAddress == USDTVAULT,
            "!Gro vault"
        );
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Constructor
    //////////////////////////////////////////////////////////////*/
    constructor(
        address _daiVault,
        address _usdcVault,
        address _usdtVault
    ) {
        DAIVAULT = _daiVault;
        USDCVAULT = _usdcVault;
        USDTVAULT = _usdtVault;
    }

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/
    /// @notice set the strategy params
    /// @param vaultAddress address for the vault associated with the strategy
    /// @param strategyIndex index of the strategy
    /// @param gasUsed gas used for harvesting the strategy
    /// @param canHarvest if harvesting via gelato is enabled for strategy
    /// @param strategyAddress address of strategy
    /// @param acceptableLoss accepted loss in which a harvest can still take place

    function setStrategyInfo(
        address vaultAddress,
        uint256 strategyIndex,
        uint256 gasUsed,
        bool canHarvest,
        address strategyAddress,
        uint256 acceptableLoss
    ) external onlyOwner onlyGroVault(vaultAddress) {
        strategyParams memory params = strategyParams(
            gasUsed,
            canHarvest,
            strategyAddress,
            acceptableLoss
        );

        strategyInfo[vaultAddress][strategyIndex] = params;
    }

    /// @notice Maximum basefee allowed for harvests
    /// @param _maxBaseFee maximum allowed basefee in gwei (send in order of 1e9)
    function setMaxBaseFee(uint256 _maxBaseFee) external onlyOwner {
        maxBaseFee = _maxBaseFee;
    }

    /*///////////////////////////////////////////////////////////////
                        Harvest Check Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice To allow the gelato network to check if a gro vault can be harvested
    /// @param _vaultAddress address of the gro vault
    /// @return canExec if a harvest should occur and execPayload calldata to run harvest
    function harvestChecker(address _vaultAddress)
        external
        view
        override
        onlyGroVault(_vaultAddress)
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 vaultStrategyLength = IVaultMK2(_vaultAddress)
            .getStrategiesLength();

        for (uint256 i = 0; i < vaultStrategyLength; i++) {
            strategyParams memory params = strategyInfo[_vaultAddress][i];
            if (block.basefee >= maxBaseFee) {
                continue;
            }

            if (!params.canHarvest) {
                continue;
            }

            if (!_canHarvestWithLoss(params._address, params.acceptableLoss)) {
                continue;
            }

            if (_investTrigger(_vaultAddress)) {
                continue;
            }

            uint256 callCost = block.basefee * params.gasUsed;

            if (IVaultMK2(_vaultAddress).strategyHarvestTrigger(i, callCost)) {
                canExec = true;
                execPayload = abi.encodeWithSelector(
                    IVaultMK2.strategyHarvest.selector,
                    uint256(i)
                );
            }

            if (canExec) break;
        }
    }

    /// @notice To allow the gelato network to check if a gro vault needs assets invested
    /// @param _vaultAddress address of the gro vault
    /// @return canExec if a invest action should occur and execPayload calldata to run invest
    function investChecker(address _vaultAddress)
        external
        view
        override
        onlyGroVault(_vaultAddress)
        returns (bool canExec, bytes memory execPayload)
    {
        if (_investTrigger(_vaultAddress)) {
            canExec = true;
            execPayload = abi.encodeWithSelector(IVaultMK2.invest.selector);
        }
    }

    /// @notice Internal check if the vault needs to invest prior to the harvest
    /// @param _vaultAddress address of the gro vault
    /// @return needs_investment bool that indicating if the vault needs to invest assets
    ///     before harvesting
    function _investTrigger(address _vaultAddress)
        private
        view
        returns (bool needs_investment)
    {
        if (IVaultMK2(_vaultAddress).investTrigger()) return true;
        else return false;
    }

    /// @notice Internal check to ensure that we would want to realize a loss through harvest
    /// @param _strategyAddress address of vault strategy
    /// @param _acceptableLoss max loss amount we would want to realized
    /// @return needs_harvest bool that indicated if the strategy needs to be harveted or not
    /// @dev This should only be applicable to strategies that run against AMMs or similar
    ///     contracts that are expected to produce temporary flucations in values that are
    ///     expected to recover after some time - this in order to prevent realising gains
    ///     and losses multiple times during drop and recover phases.
    function _canHarvestWithLoss(
        address _strategyAddress,
        uint256 _acceptableLoss
    ) private view returns (bool needs_harvest) {
        IStrategyAPI strategyAPI = IStrategyAPI(_strategyAddress);
        uint256 total = strategyAPI.estimatedTotalAssets();
        address vault = strategyAPI.vault();
        uint256 totalDebt = IVaultAPI(vault)
            .strategies(_strategyAddress)
            .totalDebt;

        if (total > totalDebt - _acceptableLoss) return true;

        return false;
    }
}
