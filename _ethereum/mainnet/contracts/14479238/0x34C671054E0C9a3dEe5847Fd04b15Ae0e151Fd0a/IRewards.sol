// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

interface IRewards {
    function stake(uint amount) external;
    function withdraw(uint amount, bool claim) external;
    function getReward() external returns (bool);
}
