// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ILinkedToILV.sol";

interface ILockedPool is ILinkedToILV {
    function vault() external view returns (address);

    function tokenLocking() external view returns (address);

    function vaultRewardsPerToken() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _staker) external view returns (uint256);

    function pendingVaultRewards(address _staker) external view returns (uint256);

    function stakeLockedTokens(address _staker, uint256 _amount) external;

    function unstakeLockedTokens(address _staker, uint256 _amount) external;

    function changeLockedHolder(address _from, address _to) external;

    function receiveVaultRewards(uint256 _amount) external;
}
