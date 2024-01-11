// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ILegitArtERC721 {
    function mintTo(
        address creator,
        uint256 royaltyFee,
        address gallerist,
        uint256 galleristFee,
        address to,
        uint256 tokenId,
        string memory tokenURI
    ) external;

    function getFeeInfo(uint256 tokenId)
        external
        view
        returns (
            address creator,
            uint256 royaltyFee,
            address gallerist,
            uint256 galleristFee
        );
}
