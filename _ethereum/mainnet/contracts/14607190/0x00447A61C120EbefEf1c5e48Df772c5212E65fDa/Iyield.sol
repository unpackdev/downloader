//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Iyield {
     function stake(
        uint256[] calldata tokenIds
    ) external;

    function unstake(
        uint256[] calldata tokenIds
    ) external;

    function claim(uint256[] calldata tokenIds) external;

    function earned(uint256[] memory tokenIds)
        external
        view
        returns (uint256);

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);

    function isOwner(address owner, uint256 tokenId)
        external
        view
        returns (bool);

    function stakedTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}