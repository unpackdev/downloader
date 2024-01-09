
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITopDog {

  // mapping (uint256 => mapping (address => UserInfo)) public userInfo;
  function userInfo(uint256 _pid, address addr) external view returns (UserInfo memory);

  struct UserInfo {
    uint256 amount;     // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation in original contract.
  }
}
