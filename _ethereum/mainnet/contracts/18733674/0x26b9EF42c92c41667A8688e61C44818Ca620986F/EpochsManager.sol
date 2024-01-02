// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IEpochsManager.sol";

contract EpochsManager is IEpochsManager {
    /// @inheritdoc IEpochsManager
    function currentEpoch() external view returns (uint16) {
        return uint16((block.timestamp - startFirstEpochTimestamp()) / epochDuration());
    }

    /// @inheritdoc IEpochsManager
    function epochDuration() public pure returns (uint256) {
        return 2592000; // NOTE: value taken from EpochsManager on Gnosis (0xFDD7d2f23F771F05C6CEbFc9f9bC2A771FAE302e)
    }

    /// @inheritdoc IEpochsManager
    function startFirstEpochTimestamp() public pure returns (uint256) {
        return 1701331199; // NOTE: value taken from EpochsManager on Gnosis (0xFDD7d2f23F771F05C6CEbFc9f9bC2A771FAE302e)
    }
}
