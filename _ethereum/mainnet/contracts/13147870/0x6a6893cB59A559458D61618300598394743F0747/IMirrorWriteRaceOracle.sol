// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IMirrorWriteRaceOracle
 * @author MirrorXYZ
 */
interface IMirrorWriteRaceOracle {
    event UpdatedRoot(bytes32 oldRoot, bytes32 newRoot);

    function updateRoot(bytes32 newRoot) external;

    function verify(
        address account,
        uint256 index,
        bytes32[] memory proof
    ) external view returns (bool);
}
