// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.7;

interface IVRFNFTSale {

  function initialize(
    address _hausAddress,
    uint256 _startTime,
    uint256 _endTime,
    address _tokenAddress,
    uint256[] memory _tokenIds,
    uint256 _priceWei,
    uint256 _limitPerOrder,
    uint256 _stakingRewardPercentageBasisPoints,
    address _stakingSwapContract,
    address _controllerAddress,
    address _vrfProvider
  ) external;
    
  function buy(uint256 amount) external payable;
  function supply() external view returns(uint256);
  function setTokenAddress(address _tokenAddress) external;
  function setTokenIds(uint256[] memory _tokenIds) external;
  function pull() external;
  function initiateRandomDistribution() external;
  function commitRandomDistribution() external;
  function claimAssigned() external;
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4);
}