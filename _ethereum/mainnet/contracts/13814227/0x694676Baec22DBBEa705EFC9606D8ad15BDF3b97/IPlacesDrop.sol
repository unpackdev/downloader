// SPDX-License-Identifier: MIT

/// @title Interface for Places drop
/// @author Places DAO

/*************************************
 * ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ *
 * ▓ ▒                           ▓ ▒ *
 * ▒          ████  ████           ▓ *
 * ▓        ██  ████  ████         ▒ *
 * ▒      ███    ███████████       ▓ *
 * ▓      ████  ████████ ███       ▒ *
 * ▒        ██████████ ███         ▓ *
 * ▓          ██████ ███           ▒ *
 * ▒            ███ ██             ▓ *
 * ▓              ██               ▒ *
 * ▒ ▓                           ▒ ▓ *
 * ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ *
 *************************************/

pragma solidity ^0.8.6;

import "./IPlaces.sol";

interface IPlacesDrop {
    function getTreasury() external view returns (address payable);

    function getPlaceCount() external view returns (uint256);

    function getEndingIndex() external view returns (uint256);

    function getPlace(uint256 tokenId)
        external
        view
        returns (IPlaces.Place memory);
}
