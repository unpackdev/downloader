// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "IVault.sol";

import "Errors.sol";
import "DataTypes.sol";
import "VotingPowerHistory.sol";

abstract contract BaseVault is IVault {
    using VotingPowerHistory for VotingPowerHistory.History;

    VotingPowerHistory.History internal history;

    function getCurrentRecord(
        address account
    ) external view returns (VotingPowerHistory.Record memory) {
        return history.currentRecord(account);
    }

    function getRawVotingPower(
        address account
    ) external view returns (uint256) {
        return getRawVotingPower(account, block.timestamp);
    }

    function getRawVotingPower(
        address account,
        uint256 timestamp
    ) public view virtual returns (uint256);
}
