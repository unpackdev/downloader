// SPDX-License-Identifier: MIT

/// @title Places provider
/// @author Places DAO

/*************************************
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 * ██░░░░░░░██████░░██████░░░░░░░░██ *
 * ░░░░░░░██████████████████░░░░░░░░ *
 * ░░░░░████████      ████████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░██████  ██████  ██████░░░░░░ *
 * ░░░░░░░████  ██████  ████░░░░░░░░ *
 * ░░░░░░░░░████      ████░░░░░░░░░░ *
 * ░░░░░░░░░░░██████████░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░██████░░░░░░░░░░░░░░ *
 * ██░░░░░░░░░░░░░██░░░░░░░░░░░░░░██ *
 * ████░░░░░░░░░░░░░░░░░░░░░░░░░████ *
 *************************************/

pragma solidity ^0.8.6;

import "./IPlaces.sol";
import "./IPlacesProvider.sol";
import "./IPlacesDrop.sol";
import "./Ownable.sol";

contract PlacesProvider is IPlacesProvider, Ownable {
    IPlacesDrop[] private drops;

    constructor(IPlacesDrop[] memory _drops) {
        drops = _drops;
    }

    /**
     * @notice Query the neighborhood treasury for the given token.
     */
    function getTreasury(uint256 tokenId)
        external
        view
        returns (address payable)
    {
        require(drops.length > 0, "Provider not setup");
        uint256 dropIndex = 0;
        while (dropIndex < drops.length) {
            if (tokenId <= drops[dropIndex].getEndingIndex()) {
                break;
            } else {
                dropIndex++;
            }
        }

        require(
            tokenId <= drops[dropIndex].getEndingIndex(),
            "Token exceeds places."
        );

        return drops[dropIndex].getTreasury();
    }

    /**
     * @notice Query the Place data for a given token.
     */
    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlaces.Place memory)
    {
        require(drops.length > 0, "Provider not setup");
        uint256 dropIndex = 0;
        while (dropIndex < drops.length) {
            if (tokenId <= drops[dropIndex].getEndingIndex()) {
                break;
            } else {
                dropIndex++;
            }
        }

        require(
            tokenId <= drops[dropIndex].getEndingIndex(),
            "Token exceeds places"
        );

        return drops[dropIndex].getPlace(tokenId);
    }

    /**
     * @notice Query the Place data for a total count.
     */
    function getPlaceSupply() external view returns (uint256 supplyCount) {
        require(drops.length > 0, "Provider not setup");
        return drops[drops.length - 1].getEndingIndex() + 1;
    }
}
