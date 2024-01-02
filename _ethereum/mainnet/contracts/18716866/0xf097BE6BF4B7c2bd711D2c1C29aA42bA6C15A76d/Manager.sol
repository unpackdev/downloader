// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.17;

import "./ITokenMetadataRenderer.sol";
import "./IManager.sol";
import "./Ownable.sol";
import "./IHouse.sol";
import "./IRound.sol";

/// @title Manager
/// @notice This contract allows an account to manage house and round implementations,
/// metadata renderers for all protocol contracts, and the security council address.
contract Manager is IManager, Ownable {
    /// @notice Determine if a contract is a registered house implementation
    /// @dev House Address => Registered
    mapping(address => bool) private houses;

    /// @notice Determine if a contract is a registered round for a house implementation
    /// @dev House Address => Round Address => Is Registered
    mapping(address => mapping(address => bool)) private rounds;

    /// @notice A mapping of contract addresses to their metadata renderers
    /// @dev Contract Address => Metadata Renderer Address
    mapping(address => address) private renderers;

    /// @notice A council that has permission to execute emergency actions
    address private securityCouncil;

    constructor() initializer {
        __Ownable_init(msg.sender);
    }

    /// @notice Determine if a house implementation is registered
    /// @param houseImpl The house implementation address
    function isHouseRegistered(address houseImpl) external view returns (bool) {
        return houses[houseImpl];
    }

    /// @notice Determine if a round implementation is registered on the provided house
    /// @param houseImpl The house implementation address
    /// @param roundImpl The round implementation address
    function isRoundRegistered(address houseImpl, address roundImpl) external view returns (bool) {
        return rounds[houseImpl][roundImpl];
    }

    /// @notice Get the metadata renderer for a contract.
    /// @param contract_ The contract address
    function getMetadataRenderer(address contract_) external view returns (ITokenMetadataRenderer) {
        return ITokenMetadataRenderer(renderers[contract_]);
    }

    /// @notice Get the security council address
    function getSecurityCouncil() external view returns (address) {
        return securityCouncil;
    }

    /// @notice Register a house implementation contract
    /// @param houseImpl The house implementation address
    function registerHouse(address houseImpl) external onlyOwner {
        houses[houseImpl] = true;

        emit HouseRegistered(houseImpl, IHouse(houseImpl).kind());
    }

    /// @notice Unregister a house implementation contract
    /// @param houseImpl The house implementation address
    function unregisterHouse(address houseImpl) external onlyOwner {
        delete houses[houseImpl];

        emit HouseUnregistered(houseImpl);
    }

    /// @notice Register a round implementation contract for a house
    /// @param houseImpl The house implementation address
    /// @param roundImpl The round implementation address
    function registerRound(address houseImpl, address roundImpl) external onlyOwner {
        rounds[houseImpl][roundImpl] = true;

        emit RoundRegistered(houseImpl, roundImpl, IRound(roundImpl).kind());
    }

    /// @notice Unregister a round implementation contract for a house
    /// @param houseImpl The house implementation address
    /// @param roundImpl The round implementation address
    function unregisterRound(address houseImpl, address roundImpl) external onlyOwner {
        delete rounds[houseImpl][roundImpl];

        emit RoundUnregistered(houseImpl, roundImpl);
    }

    /// @notice Set a metadata renderer for a contract.
    /// @param contract_ The contract address
    /// @param renderer The renderer address
    function setMetadataRenderer(address contract_, address renderer) external onlyOwner {
        renderers[contract_] = renderer;

        emit MetadataRendererSet(contract_, renderer);
    }

    /// @notice Sets the security council to a new account (`newSecurityCouncil`)
    /// @param newSecurityCouncil The new security council address
    function setSecurityCouncil(address newSecurityCouncil) external onlyOwner {
        securityCouncil = newSecurityCouncil;

        emit SecurityCouncilSet(newSecurityCouncil);
    }
}
