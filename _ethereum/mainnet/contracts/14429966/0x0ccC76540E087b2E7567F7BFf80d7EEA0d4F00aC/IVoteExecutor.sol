// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IAccessControl.sol";
import "./IEntry.sol";

interface IVoteExecutor is IAccessControl, IEntry {
    /**
     * @dev Main function for executing votes
     * by providing enries
     * @param _entries full info about entry
     */
    function execute(Entry[] memory _entries) external;
}
