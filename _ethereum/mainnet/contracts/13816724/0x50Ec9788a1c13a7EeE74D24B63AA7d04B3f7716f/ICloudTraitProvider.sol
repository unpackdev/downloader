// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICloudTraits.sol";

/// @title CloudCollective NFT Interface for provided ICloudTraits
interface ICloudTraitProvider{

    /// Returns the ButterflyEffect for the given cloud
    /// @param tokenId The ID of the token that represents the Cloud
    /// @return The Forecast structure
    function butterflyEffect(uint256 tokenId) external view returns (ICloudTraits.ButterflyEffect memory);

    /// Returns the cloud forecast associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Cloud
    /// @return forecast memory
    function cloudForecast(uint256 tokenId) external view returns (ICloudTraits.Forecast memory forecast);

    /// Returns the text of a cloud condition
    /// @param condition The Condition
    /// @return The condition text
    function conditionName(ICloudTraits.Condition condition) external pure returns (string memory);

    /// Returns the text of the cloud energy category
    /// @param energyCategory The EnergyCategory
    /// @return the energy category text
    function energyCategoryName(ICloudTraits.EnergyCategory energyCategory) external pure returns (string memory);

    /// Represents the text of the cloud energy state
    /// @param forecast The forecast obtained from `forecastForCloud()`
    /// @return The cloud energy state text
    function energyStateName(ICloudTraits.Forecast memory forecast) external view returns (string memory);

    /// Returns the text of a cloud scale
    /// @param scale The Scale
    /// @return The scale text
    function scaleName(ICloudTraits.Scale scale) external pure returns (string memory);
}
