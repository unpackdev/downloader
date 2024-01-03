// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface PickleStaking {
    function balanceOf(address account) external view returns (uint);

    function earned(address account) external view returns (uint);

    function stake(uint amount) external;

    function withdraw(uint amount) external;

    function getReward() external;

    function exit() external;
}
