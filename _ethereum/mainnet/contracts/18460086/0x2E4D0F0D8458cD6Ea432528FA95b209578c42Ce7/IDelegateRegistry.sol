// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegateRegistry {
    function delegation(
        address _delegator,
        bytes32 _id
    ) external view returns (address);

    function setDelegate(bytes32 _id, address _delegate) external;
}
