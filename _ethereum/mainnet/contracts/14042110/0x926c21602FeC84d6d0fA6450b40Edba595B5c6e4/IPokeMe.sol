// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IPokeMe {
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32);

    function cancelTask(bytes32 _taskId) external;

    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector,
        bool _useTaskTreasuryFunds,
        address _feeToken,
        bytes32 _resolverHash
    ) external pure returns (bytes32);

    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);

    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    function taskTreasury() external view returns (address);

    function gelato() external view returns (address payable);

    function getFeeDetails() external view returns (uint256, address);
}
