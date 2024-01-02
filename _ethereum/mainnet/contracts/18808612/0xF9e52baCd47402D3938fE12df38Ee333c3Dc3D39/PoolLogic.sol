// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IYToken.sol";
import "./ReserveConfiguration.sol";
import "./Errors.sol";
import "./WadRayMath.sol";
import "./DataTypes.sol";
import "./ReserveLogic.sol";
import "./ERC1155ReserveLogic.sol";
import "./ValidationLogic.sol";
import "./GenericLogic.sol";
import "./IPool.sol";

/**
 * @title PoolLogic library
 *
 * @notice Implements the logic for Pool specific functions
 */
library PoolLogic {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;
    using ReserveLogic for DataTypes.ReserveData;
    using ERC1155ReserveLogic for DataTypes.ERC1155ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /**
     * @notice Initialize an asset reserve and add the reserve to the list of reserves
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for initiation
     * @return true if appended, false if inserted at existing empty spot
     */
    function executeInitReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.InitReserveParams memory params
    ) external returns (bool) {
        reservesData[params.asset].init(
            params.yTokenAddress, params.variableDebtAddress, params.interestRateStrategyAddress
        );

        bool reserveAlreadyAdded = reservesData[params.asset].id != 0 || reservesList[0] == params.asset;
        require(!reserveAlreadyAdded, Errors.RESERVE_ALREADY_ADDED);

        for (uint16 i = 0; i < params.reservesCount; i++) {
            if (reservesList[i] == address(0)) {
                reservesData[params.asset].id = i;
                reservesList[i] = params.asset;
                return false;
            }
        }

        require(params.reservesCount < params.maxNumberReserves, Errors.NO_MORE_RESERVES_ALLOWED);
        reservesData[params.asset].id = params.reservesCount;
        reservesList[params.reservesCount] = params.asset;
        return true;
    }

    /**
     * @notice Initialize an ERC1155 asset reserve
     * @param erc1155ReservesData The state of all the ERC1155 reserves
     * @param params Additional parameters needed for initiation
     */
    function executeInitERC1155Reserve(
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.InitERC1155ReserveParams memory params
    ) external {
        erc1155ReservesData[params.asset].init(params.nTokenAddress, params.configurationProvider);
    }

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function executeRescueTokens(address token, address to, uint256 amount) external {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of yTokens
     * @param reservesData The state of all the reserves
     * @param assets The list of reserves for which the minting needs to be executed
     */
    function executeMintToTreasury(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address[] calldata assets
    ) external {
        for (uint256 i = 0; i < assets.length; i++) {
            address assetAddress = assets[i];

            DataTypes.ReserveData storage reserve = reservesData[assetAddress];

            // this cover both inactive reserves and invalid reserves since the flag will be 0 for both
            if (!reserve.configuration.getActive()) {
                continue;
            }

            uint256 accruedToTreasury = reserve.accruedToTreasury;

            if (accruedToTreasury != 0) {
                reserve.accruedToTreasury = 0;
                uint256 normalizedIncome = reserve.getNormalizedIncome();
                uint256 amountToMint = accruedToTreasury.rayMul(normalizedIncome);
                IYToken(reserve.yTokenAddress).mintToTreasury(amountToMint, normalizedIncome);

                emit IPool.MintedToTreasury(assetAddress, amountToMint);
            }
        }
    }

    /**
     * @notice Drop a reserve
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param asset The address of the underlying asset of the reserve
     */
    function executeDropReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        address asset
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        ValidationLogic.validateDropReserve(reservesList, reserve, asset);
        reservesList[reservesData[asset].id] = address(0);
        delete reservesData[asset];
    }

    /**
     * @notice Drop a reserve
     * @param erc1155ReservesData The state of all the reserves
     * @param asset The address of the underlying asset of the reserve
     */
    function executeDropERC1155Reserve(
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        address asset
    ) external {
        DataTypes.ERC1155ReserveData storage reserve = erc1155ReservesData[asset];
        ValidationLogic.validateDropERC1155Reserve(reserve, asset);
        delete erc1155ReservesData[asset];
    }

    /**
     * @notice Returns the user account data across all the reserves
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional params needed for the calculation
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function executeGetUserAccountData(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.ERC1155ReserveData) storage erc1155ReservesData,
        DataTypes.UserERC1155ConfigurationMap storage userERC1155Config,
        DataTypes.CalculateUserAccountDataParams memory params
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        (totalCollateralBase, totalDebtBase, ltv, currentLiquidationThreshold, healthFactor,) = GenericLogic
            .calculateUserAccountData(reservesData, reservesList, erc1155ReservesData, userERC1155Config, params);

        availableBorrowsBase = GenericLogic.calculateAvailableBorrows(totalCollateralBase, totalDebtBase, ltv);
    }
}
