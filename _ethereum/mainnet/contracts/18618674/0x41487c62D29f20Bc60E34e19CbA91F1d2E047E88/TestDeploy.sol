// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.

pragma solidity ^0.8.10;

contract TestDeploy {
    struct Call {
        address target;
        bytes callData;
    }

    function abecuiosdf(Call[] memory calls) public view returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
    }
}
