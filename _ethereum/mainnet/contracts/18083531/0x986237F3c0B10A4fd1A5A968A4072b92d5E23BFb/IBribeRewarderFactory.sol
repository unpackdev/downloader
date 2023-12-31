// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./IERC20.sol";

interface IBribeRewarderFactory {
    function isRewardTokenWhitelisted(IERC20 _token) external view returns (bool);
}
