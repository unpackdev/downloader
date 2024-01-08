// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

interface IEnglishAuctionReservePrice {

  function initialize(
    uint256 _tokenId,
    address _tokenAddress,
    uint256 _reservePriceWei,
    uint256 _minimumStartTime,
    uint256 _stakingRewardPercentageBasisPoints,
    uint8 _percentageIncreasePerBid,
    address _hausAddress,
    address _stakingSwapContract,
    address _controllerAddress
  ) external;
      
  function bid() external payable;
  
  function end() external;
  
  function pull() external;
  
  function live() external view returns(bool);

  function containsAuctionNFT() external view returns(bool);
  
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4);
}