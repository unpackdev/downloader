// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Interface for the ERC-2981 royalties standard.
interface IERC2981 {

/// @notice RoyaltiesInfo stores token royalties information.
struct RoyaltiesInfo {

    /// @notice The address to which royalties will be directed.
    address receiver;

    /// @notice The royalties amount, in bips.
    uint96 royalties;

}

    /// @notice Returns the address to which royalties are received along with
    ///  the royalties amount to be paid to them for a given sale price.
    /// @param id The id of the NFT being queried for royalties information.
    /// @param salePrice The sale price of the NFT, in some unit of exchange.
    /// @return receiver The address of the royalties receiver.
    /// @return royaltyAmount The royalty payment to be made given `salePrice`.
    function royaltyInfo(
        uint256 id,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

}
