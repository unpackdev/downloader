// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ILotteryNFT {

    function newLotteryItem(address player, uint8[4] memory _lotteryNumbers, uint256 _amount, uint256 _issueIndex) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
    function getClaimStatus(uint256 tokenId) external view returns (bool);
    function claimReward(uint256 tokenId) external;
    function multiClaimReward(uint256[] memory _tokenIds) external;
    function getLotteryIssueIndex(uint256 tokenId) external view returns (uint256);
    function getLotteryNumbers(uint256 tokenId) external view returns (uint8[4] memory);
    function getLotteryAmount(uint256 tokenId) external view returns (uint256);
}