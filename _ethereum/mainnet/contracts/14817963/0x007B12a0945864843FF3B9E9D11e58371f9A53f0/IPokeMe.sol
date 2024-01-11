// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

interface IPokeMe {
    function createTaskNoPrepayment(
        address execAddress_,
        bytes4 execSelector_,
        address resolverAddress_,
        bytes calldata resolverData_,
        address feeToken_
    ) external returns (bytes32 task);

    function cancelTask(bytes32 taskId_) external;

    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external;

    function getFeeDetails() external view returns (uint256, address);

    function getResolverHash(
        address _resolverAddress,
        bytes memory _resolverData
    ) external pure returns (bytes32);
}
