// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./IERC1155ConfigurationProvider.sol";
import "./SafeERC20.sol";
import "./IVariableDebtToken.sol";
import "./IReserveInterestRateStrategy.sol";
import "./ReserveConfiguration.sol";
import "./MathUtils.sol";
import "./WadRayMath.sol";
import "./PercentageMath.sol";
import "./Errors.sol";
import "./DataTypes.sol";
import "./SafeCast.sol";

/**
 * @title ERC1155ReserveLogic library
 *
 * @notice Implements the logic to update ERC1155 reserves state
 */
library ERC1155ReserveLogic {
    using ERC1155ReserveLogic for DataTypes.ERC1155ReserveData;

    function getConfiguration(DataTypes.ERC1155ReserveData storage erc1155Reserve, uint256 tokenId)
        internal
        view
        returns (DataTypes.ERC1155ReserveConfiguration memory)
    {
        return IERC1155ConfigurationProvider(erc1155Reserve.configurationProvider).getERC1155ReserveConfig(tokenId);
    }

    /**
     * @notice Initializes a reserve.
     * @param reserve The reserve object
     * @param nTokenAddress The address of the overlying ntoken contract
     * @param configurationProvider The address of the configuration provider
     */
    function init(DataTypes.ERC1155ReserveData storage reserve, address nTokenAddress, address configurationProvider)
        internal
    {
        require(reserve.nTokenAddress == address(0), Errors.RESERVE_ALREADY_INITIALIZED);

        reserve.configurationProvider = configurationProvider;
        reserve.nTokenAddress = nTokenAddress;
    }
}
