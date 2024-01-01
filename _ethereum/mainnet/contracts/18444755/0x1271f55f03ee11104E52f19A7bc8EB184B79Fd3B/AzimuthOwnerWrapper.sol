pragma solidity ^0.8.18;

import "./Interfaces.sol";

/// @notice A wrapper contract for interfacing with the Azimuth point system.
/// @dev Provides a stable `ownerOf` method that does not depend on the potentially self-destructing Ecliptic contract.
contract AzimuthOwnerWrapper {
    IAzimuth public azimuthContract;
    
    /// @notice Initialize the contract with a given Azimuth contract.
    /// @param _azimuthContract The address of the Azimuth contract.
    constructor(IAzimuth _azimuthContract) {
        azimuthContract = _azimuthContract;
    }

    /// @notice Returns the Ecliptic contract associated with the current Azimuth contract.
    /// @return The Ecliptic contract address.
    function eclipticContract()
        public
        view
        returns(IEcliptic)
    {
        return IEcliptic(azimuthContract.owner());
    }

    /// @notice Retrieve the owner of a given Azimuth point.
    /// @param tokenId The ID of the Azimuth point.
    /// @return The address of the token owner.
    function ownerOf(uint256 tokenId) external view returns (address) {
        return eclipticContract().ownerOf(tokenId);
    }
}