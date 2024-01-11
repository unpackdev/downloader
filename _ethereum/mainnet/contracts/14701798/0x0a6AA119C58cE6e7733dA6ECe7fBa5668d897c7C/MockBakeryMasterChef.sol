// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";

contract MockBakeryMasterChef {
  function deposit(address _token, uint256 _amount) external {
    IERC20(_token).transferFrom(msg.sender, address(42), _amount);
  }

  function withdraw(address, uint256) external {}

  function poolUserInfoMap(address, address) external pure returns (uint256 amount, uint256 rewardDebt) {
    return (0, 0);
  }
}
