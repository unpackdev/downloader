// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

interface IVirtualRewards {
    function stake(address addr, uint amount) external;

    function withdraw(address addr, uint amount) external;

    function getReward(address addr) external;
}
