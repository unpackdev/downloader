// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

interface ICHIManager {
    function chi(uint256 tokenId)
        external
        view
        returns (
            address owner,
            address operator,
            address pool,
            address vault,
            uint256 accruedProtocolFees0,
            uint256 accruedProtocolFees1,
            uint24 fee,
            uint256 totalShares
        );

    function yang(uint256 yangId, uint256 chiId)
        external
        view
        returns (uint256 shares);
}
