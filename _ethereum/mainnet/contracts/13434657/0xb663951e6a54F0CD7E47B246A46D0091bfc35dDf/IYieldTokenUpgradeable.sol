//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IYieldTokenUpgradeable is IERC20Upgradeable {
    function updateRewardOnMint(address _user, uint256 _amount) external;

    function updateReward(address _from, address _to) external;

    function getReward(address _to) external;

    function burn(address _from, uint256 _amount) external;

    function getTotalClaimable(address _user) external view returns (uint256);
}
