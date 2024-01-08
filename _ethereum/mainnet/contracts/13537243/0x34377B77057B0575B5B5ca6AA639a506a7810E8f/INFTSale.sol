// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

interface INFTSale {

  function initialize(
    address _hausAddress,
    uint256 _startTime,
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _priceWei,
    uint256 _limitPerOrder,
    uint256 _stakingRewardPercentageBasisPoints,
    address _stakingSwapContract,
    address _controllerAddress
  ) external;

  function buy(uint256 amount) external payable;

  function supply() external view returns(uint256);

  function setTokenAddress(address _tokenAddress) external;

  function setTokenId(uint256 _tokenId) external;

  function pull() external;

  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4);

}