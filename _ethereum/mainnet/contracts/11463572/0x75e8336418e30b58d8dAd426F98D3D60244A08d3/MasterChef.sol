// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface MasterChef {
    function userInfo(uint _pid, address _user)
        external
        view
        returns (uint _amount, uint _rewardDebt);

    function deposit(uint _pid, uint _amount) external;

    function withdraw(uint _pid, uint _amount) external;
}
