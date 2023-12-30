// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IMaverickRewardOpenSlim {
  function MAX_REWARD_TOKENS (  ) external view returns ( uint8 );
  function balanceOf ( address ) external view returns ( uint256 );
  function earned ( address account, address rewardTokenAddress ) external view returns ( uint256 );
  function getReward ( address recipient, uint8[] memory rewardTokenIndices ) external;
  function getReward ( address recipient, uint8 rewardTokenIndex ) external returns ( uint256 );
  function globalActive (  ) external view returns ( uint256 _data );
  function multicall ( bytes[] memory data ) external returns ( bytes[] memory results );
  function notifyAndTransfer ( address rewardTokenAddress, uint256 amount, uint256 duration ) external;
  function removeStaleToken ( uint8 rewardTokenIndex ) external;
  function rewardData ( uint256 ) external view returns ( uint256 finishAt, uint256 updatedAt, uint256 rewardRate, uint256 rewardPerTokenStored, uint256 escrowedReward, uint256 globalResetCount, address rewardToken );
  function rewardFactory (  ) external view returns ( address );
  function rewardInfo (  ) external view returns ( bytes[] memory info );
  function stake ( uint256 amount, address account ) external;
  function stakingToken (  ) external view returns ( address );
  function tokenIndex ( address ) external view returns ( uint8 );
  function totalSupply (  ) external view returns ( uint256 );
  function unstake ( uint256 amount, address recipient ) external;
  function unstakeAll ( address recipient ) external;
}
