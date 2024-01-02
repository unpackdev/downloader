// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

/**
 * @title IPotionDelegatedFillContract
 * @author Pybast.eth - Nefture
 * @custom:lead Antoine Bertin - Clopr
 * @dev Interface for future upgradeability of potion fill mechanisms, enabling integration of custom fill logic within the Clopr ecosystem.
 */
interface IPotionDelegatedFillContract {
    /// @notice Retrieve the fill level of a Clopr Bottle
    /// @dev allows a potion fill contract to implement its own fill level logic
    /// @param tokenId ID of the CloprBottle
    /// @return fillLevel fill level of the CloprBottle
    function getFillLevel(
        uint256 tokenId
    ) external view returns (uint8 fillLevel);
}
