// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Errors.sol";
import "./DataTypes.sol";
import "./ReserveConfiguration.sol";

/**
 * @title UserConfiguration library
 *
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserERC1155Configuration {
    /**
     * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
     * @param self The configuration object
     * @param asset Address of the ERC1155 asset
     * @param tokenId The id of token enabled
     * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
     */
    function setUsingAsCollateral(
        DataTypes.UserERC1155ConfigurationMap storage self,
        address asset,
        uint256 tokenId,
        bool usingAsCollateral
    ) internal {
        if (usingAsCollateral) {
            self.usedERC1155Reserves.push(DataTypes.ERC1155ReserveUsageData({asset: asset, tokenId: tokenId}));
            self.usedERC1155ReservesMap[asset][tokenId] = self.usedERC1155Reserves.length;
        } else {
            // This will cause underflow for non-existent reserves
            uint256 index = self.usedERC1155ReservesMap[asset][tokenId] - 1;

            delete self.usedERC1155ReservesMap[asset][tokenId];
            uint256 lastIndex = self.usedERC1155Reserves.length - 1;

            if (lastIndex == index) {
                self.usedERC1155Reserves.pop();
                return;
            } else {
                DataTypes.ERC1155ReserveUsageData memory lastReserve = self.usedERC1155Reserves[lastIndex];
                self.usedERC1155Reserves[index] = lastReserve;
                self.usedERC1155Reserves.pop();
                self.usedERC1155ReservesMap[lastReserve.asset][lastReserve.tokenId] = index + 1;
            }
        }
    }

    /**
     * @notice Checks if a user has been supplying any reserve as collateral
     * @param self The configuration object
     * @return True if the user has been supplying as collateral any reserve, false otherwise
     */
    function isUsingAsCollateralAny(DataTypes.UserERC1155ConfigurationMap storage self) internal view returns (bool) {
        return self.usedERC1155Reserves.length > 0;
    }

    /**
     * @notice Checks if a user is using as collateral a specific reserve
     * @param self The configuration object
     * @param asset The address of the reserve
     * @param tokenId The tokenId of reserve
     * @return True if the user is using the reserve as collateral, false otherwise
     */
    function isUsingAsCollateral(DataTypes.UserERC1155ConfigurationMap storage self, address asset, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return self.usedERC1155ReservesMap[asset][tokenId] > 0;
    }

    /**
     * @notice Returns count of the reserves used as collateral by the user
     * @param self The configuration object
     * @return The number of reserves used as collateral
     */
    function getUsedReservesCount(DataTypes.UserERC1155ConfigurationMap storage self) internal view returns (uint256) {
        return self.usedERC1155Reserves.length;
    }
}
