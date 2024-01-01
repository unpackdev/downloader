// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC721.sol";

interface IRNFTV1 is IERC721 {
    function seed(uint256 tokenId) external view returns (bytes32);

    function originalOwner(uint256 tokenId) external view returns (address);

    function ownedTokens(
        address owner
    ) external view returns (uint256[] memory);

    function hasOwnedToken(
        address toAddress,
        uint256 tokenId
    ) external view returns (bool);

    function totalSupply() external view returns (uint256);
}
