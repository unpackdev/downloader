pragma solidity 0.5.16;

interface IHardRewards {
  function rewardMe(address recipient, address vault) external;
}
