// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "./ITokenMetadataRenderer.sol";

/// @notice Interface for the Manager contract
interface IManager {
    /// @notice Emitted when a house implementation is registered
    /// @param houseImpl The house implementation address
    /// @param houseType The house implementation type
    event HouseRegistered(address houseImpl, bytes32 houseType);

    /// @notice Emitted when a house implementation is unregistered
    /// @param houseImpl The house implementation address
    event HouseUnregistered(address houseImpl);

    /// @notice Emitted when a round implementation is registered on a house
    /// @param houseImpl The house implementation address
    /// @param roundImpl The round implementation address
    /// @param roundType The round implementation type
    event RoundRegistered(address houseImpl, address roundImpl, bytes32 roundType);

    /// @notice Emitted when a round implementation is unregistered on a house
    /// @param houseImpl The house implementation address
    /// @param roundImpl The round implementation address
    event RoundUnregistered(address houseImpl, address roundImpl);

    /// @notice Emitted when a metadata renderer is set for a contract
    /// @param addr The contract address
    /// @param renderer The renderer address
    event MetadataRendererSet(address addr, address renderer);

    /// @notice Emitted when the security council address is set
    /// @param securityCouncil The security council address
    event SecurityCouncilSet(address securityCouncil);

    /// @notice Determine if a house implementation is registered
    /// @param houseImpl The house implementation address
    function isHouseRegistered(address houseImpl) external view returns (bool);

    /// @notice Determine if a round implementation is registered on the provided house
    /// @param houseImpl The house implementation address
    /// @param roundImpl The round implementation address
    function isRoundRegistered(address houseImpl, address roundImpl) external view returns (bool);

    /// @notice Get the metadata renderer for a contract
    /// @param contract_ The contract address
    function getMetadataRenderer(address contract_) external view returns (ITokenMetadataRenderer);

    /// @notice Get the security council address
    function getSecurityCouncil() external view returns (address);
}
