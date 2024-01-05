// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ConnectGelatoInstaDappBase.sol";

function _verifyTask(
    address _taskStorage,
    address _owner,
    bytes memory _bytesBlob,
    uint256 _id
) view {
    require(
        (ConnectGelatoInstaDappBase(_taskStorage).taskOwner(
            _hashTask(_bytesBlob, _id)
        ) == _owner),
        "_verifyTask: invalid task"
    );
}

function _hashTask(bytes memory _bytesBlob, uint256 _taskId)
    pure
    returns (bytes32)
{
    return keccak256(abi.encode(_bytesBlob, _taskId));
}
