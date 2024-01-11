// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC20Upgradeable.sol";

interface IERC20StakingLocker is IERC20Upgradeable {
    function lock(address, uint256) external;

    function unlock(address, uint256) external;

    function locked(address) external view returns (uint256);
}