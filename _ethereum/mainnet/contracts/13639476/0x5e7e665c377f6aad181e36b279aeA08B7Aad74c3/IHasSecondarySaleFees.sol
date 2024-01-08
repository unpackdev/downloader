// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 */
interface IHasSecondarySaleFees {
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);

    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}