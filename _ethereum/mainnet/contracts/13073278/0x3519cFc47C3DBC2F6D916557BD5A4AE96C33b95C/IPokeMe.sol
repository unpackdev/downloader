// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IPokeMe {
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external;

    function cancelTask(bytes32 _taskId) external;

    // function withdrawFunds(uint256 _amount) external;

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector
    ) external pure returns (bytes32);
}
