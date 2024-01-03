// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./ERC1155Farm.sol";

contract NFTRewardsVault is ERC1155Farm {
  constructor(address _rewardToken) public ERC1155Farm(_rewardToken) {}
}
