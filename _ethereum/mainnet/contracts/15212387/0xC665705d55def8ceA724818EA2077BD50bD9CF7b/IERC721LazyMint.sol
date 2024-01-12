// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC721Upgradeable.sol";
import "./LibERC721LazyMint.sol";

interface IERC721LazyMint is IERC721Upgradeable {
    event Creator(
        uint256 tokenId,
        address creator,
        uint256 royaltyFee
    );

    function mintAndTransfer(
        LibERC721LazyMint.Mint721Data memory data,
        address to
    ) external;

    function transferFromOrMint(
        LibERC721LazyMint.Mint721Data memory data,
        address from,
        address to
    ) external;

    function getRoyaltyFee(uint256 _id) external returns (uint);

    function getCreator(uint256 _id) external returns (address);
}
