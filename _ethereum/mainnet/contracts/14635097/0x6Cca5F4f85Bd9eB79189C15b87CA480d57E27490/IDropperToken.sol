// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC1155.sol";

interface IDropperToken is IERC1155 {
    function tryAddMintable(address[] memory to, uint256[] memory amounts, address tokenAddress, uint256 tokenId) external;

    function tryAddMintableBatch(address[] memory to, uint256[] memory amounts, address tokenAddress, uint256[] memory tokenIds) external;

    function addReward(address tokenAddress) external payable;

    function claimRewardBatch(uint256[] calldata ids) external;

    function claimTokens(uint256 id) external;

    function claimTokensBatch(uint256[] calldata ids) external;

    function getId(address tokenAddress) external view returns (uint256);

    function mintableBalanceOf(address owner, uint256 id) external view returns (uint256);
}