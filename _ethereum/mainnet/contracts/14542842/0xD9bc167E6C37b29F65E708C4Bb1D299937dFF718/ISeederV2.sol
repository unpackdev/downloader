// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
interface ISeederV2 {
    function getBatch() external view returns (uint256);
    function getReqByBatch(uint256 batch) external view returns (bytes32);
    function getNextAvailableBatch() external view returns (uint256);

    function executeRequestMulti() external;
}
