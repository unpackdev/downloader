// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

/// @notice Interface for the CHYPC.sol contract.
interface IHyperCycleLicense is IERC721 {
    /**
     * Accesses the assignment function of c_HyPC so the swap can remove 
     * the assignment data when a token is redeemed or swapped.
     */
    /// @notice Creates a new root token inside this contract, with a specified licenseID.
    function mint(
        uint256 numTokens
    ) external;

    /// @notice Splits a given token into two new tokens, with corresponding licenseID's.
    function split(
        uint256 tokenId
    ) external;

    /// @notice Burns a given tokenId with a specified burn string.
    function burn(
        uint256 tokenId,
        string memory burnString          
    ) external;

    /// @notice Merges together two child licenses into a parent license.
    function merge(
        uint256 tokenId
    ) external;

    /// @notice Returns the burn data from the given tokenId.
    function getBurnData(
        uint256 tokenId
    ) external view returns (string memory);

    /// @notice Returns the license height of the given tokenId.
    function getLicenseHeight(
        uint256 licenseId
    ) external view returns (uint8);

    /// @notice Returns the license height of the given tokenId.
    function getLicenseStatus(
        uint256 licenseId
    ) external view returns (uint256);
}
