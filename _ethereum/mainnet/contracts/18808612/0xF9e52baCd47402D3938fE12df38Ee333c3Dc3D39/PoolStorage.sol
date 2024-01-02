// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./UserConfiguration.sol";
import "./ReserveConfiguration.sol";
import "./ReserveLogic.sol";
import "./DataTypes.sol";

/**
 * @title PoolStorage
 *
 * @notice Contract used as storage of the Pool contract.
 * @dev It defines the storage layout of the Pool contract.
 */
contract PoolStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // Map of reserves and their data (underlyingAssetOfReserve => reserveData)
    mapping(address => DataTypes.ReserveData) internal _reserves;

    // Map of ERC1155 reserves and their data (underlyingAssetOfReserve => reserveData)
    mapping(address => DataTypes.ERC1155ReserveData) internal _erc1155Reserves;

    // Map of users address and their configuration data (userAddress => userConfiguration)
    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    // Map of users address and their configuration data for ERC1155 reserves (userAddress => userConfiguration)
    mapping(address => DataTypes.UserERC1155ConfigurationMap) internal _usersERC1155Config;

    // List of reserves as a map (reserveId => reserve).
    // It is structured as a mapping for gas savings reasons, using the reserve id as index
    mapping(uint256 => address) internal _reservesList;

    // Total FlashLoan Premium, expressed in bps
    uint128 internal _flashLoanPremiumTotal;

    // FlashLoan premium paid to protocol treasury, expressed in bps
    uint128 internal _flashLoanPremiumToProtocol;

    // Maximum number of active reserves there have been in the protocol. It is the upper bound of the reserves list
    uint16 internal _reservesCount;

    // Maximum number of ERC1155 collateral reserves a user can have
    uint256 internal _maxERC1155CollateralReserves;
}
