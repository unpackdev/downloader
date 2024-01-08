// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./SapphireTypes.sol";

interface ISapphireCreditScore {
    function updateMerkleRoot(bytes32 newRoot) external;

    function setMerkleRootUpdater(address merkleRootUpdater) external;

    function verifyAndUpdate(SapphireTypes.ScoreProof calldata proof) external returns (uint256, uint16);

    function getLastScore(address user) external view returns (uint256, uint16, uint256);

    function setMerkleRootDelay(uint256 delay) external;

    function setPause(bool status) external;
}
