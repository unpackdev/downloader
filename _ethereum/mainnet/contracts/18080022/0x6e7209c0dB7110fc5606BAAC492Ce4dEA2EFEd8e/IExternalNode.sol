//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC165.sol";

import "./NodeOutput.sol";
import "./NodeDefinition.sol";

/// @title Interface for an external node
interface IExternalNode is IERC165 {
    function process(
        NodeOutput.Data[] memory parentNodeOutputs,
        bytes memory parameters,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) external view returns (NodeOutput.Data memory);

    function isValid(NodeDefinition.Data memory nodeDefinition) external returns (bool);
}
