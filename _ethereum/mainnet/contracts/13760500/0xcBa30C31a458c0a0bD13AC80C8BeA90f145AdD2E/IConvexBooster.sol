pragma solidity ^0.8.9;

interface IConvexBooster {
  function staker() external view returns (address);

  function poolInfo(uint256)
    external
    view
    returns (
      address, // lptoken
      address, // token
      address, // gauge
      address, // crvRewards
      address, // stash
      bool // shutdown
    );
}
