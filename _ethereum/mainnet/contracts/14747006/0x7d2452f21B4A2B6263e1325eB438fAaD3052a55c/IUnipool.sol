//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IUnipool {
    function withdrawFrom(address _user, uint256 amount) external;

    function allowance(address _owner, address _spender) external view returns (uint256);

    function getReward(address _user) external;

    function balanceOf(address _owner) external view returns (uint256);

    function stakeFor(address _user, uint256 _amount) external;
}
