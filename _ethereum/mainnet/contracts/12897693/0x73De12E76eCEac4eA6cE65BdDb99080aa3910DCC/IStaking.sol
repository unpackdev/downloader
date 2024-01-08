pragma solidity 0.5.17;


/**
 * @title Staking interface, as defined by EIP-900.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract IStaking
{
  event Staked(address indexed user, uint amount, uint total, bytes data);
  event Unstaked(address indexed user, uint amount, uint total, bytes data);

  function stake(uint amount, bytes calldata data) external;

  function stakeFor(address user, uint amount, bytes calldata data) external;

  function unstake(uint amount, bytes calldata data) external;

  function totalStakedFor(address addr) public view returns (uint);

  function totalStaked() public view returns (uint);

  function token() external view returns (address);

  /**
   * @return false. This application does not support staking history.
   */
  function supportsHistory() external pure returns (bool)
  {
    return false;
  }
}
