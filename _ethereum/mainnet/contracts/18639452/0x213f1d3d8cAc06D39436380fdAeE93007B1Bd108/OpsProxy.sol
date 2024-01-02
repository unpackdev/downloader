pragma solidity ^0.8.20;

interface OpsProxy {
    function batchExecuteCall(
        address[] calldata _targets,
        bytes[] calldata _datas,
        uint256[] calldata _values
    ) external payable;

    function owner() external returns (address);
}