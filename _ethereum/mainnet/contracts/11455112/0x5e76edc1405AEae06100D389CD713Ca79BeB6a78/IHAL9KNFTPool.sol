pragma solidity ^0.6.0;

interface IHAL9KNFTPool {
   function isHal9kStakingStarted(address sender) external view returns(bool);
   function doHal9kStaking(address sender, uint256 stakeAmount, uint256 currentTime) external;
   function withdrawLP(address sender, uint256 stakeAmount) external;
}
