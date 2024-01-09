// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
import "./IERC20.sol";

interface IRewarder {
    function onAPWReward(
        uint256 pid,
        address user,
        address recipient,
        uint256 apwAmount
    ) external;

    function pendingTokens(uint256 pid, address user) external view returns (IERC20[] memory, uint256[] memory);

    function renewPool(uint256 _oldPid, uint256 _newPid) external;
}
