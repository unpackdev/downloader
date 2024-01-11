// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IERC1155Upgradeable.sol";

interface IERC1155StakingLocker is IERC1155Upgradeable {
    function lock(
        address,
        uint256[] memory,
        uint256[] memory
    ) external;

    function unlock(
        address,
        uint256[] memory,
        uint256[] memory
    ) external;

    function locked(address, uint256) external view returns (uint256);
}