//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries

// Contracts

// Interfaces
import "./IStaking.sol";

interface IERC721Staking is IStaking {
    function stakeAll(uint256 pid, uint256[] calldata ids) external;

    function stakeAll(uint256 pid) external;

    function unstakeAll(uint256 pid) external;

    function unstakeAll(uint256 pid, uint256[] memory ids) external;
}
