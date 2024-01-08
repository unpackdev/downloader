// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ConsiderationStructs.sol";

import "./TestContractOfferer.sol";

contract TestInvalidContractOffererRatifyOrder is TestContractOfferer {
    constructor(address seaport) TestContractOfferer(seaport) {}

    function ratifyOrder(
        SpentItem[] calldata,
        ReceivedItem[] calldata,
        bytes calldata,
        bytes32[] calldata,
        uint256
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("throw"));
    }
}
