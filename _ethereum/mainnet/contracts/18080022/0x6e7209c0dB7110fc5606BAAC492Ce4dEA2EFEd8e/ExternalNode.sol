// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./ERC165Helper.sol";

import "./NodeDefinition.sol";
import "./NodeOutput.sol";
import "./IExternalNode.sol";

library ExternalNode {
    function process(
        NodeOutput.Data[] memory prices,
        bytes memory parameters,
        bytes32[] memory runtimeKeys,
        bytes32[] memory runtimeValues
    ) internal view returns (NodeOutput.Data memory nodeOutput) {
        IExternalNode externalNode = IExternalNode(abi.decode(parameters, (address)));
        return externalNode.process(prices, parameters, runtimeKeys, runtimeValues);
    }

    function isValid(NodeDefinition.Data memory nodeDefinition) internal returns (bool valid) {
        // Must have correct length of parameters data
        if (nodeDefinition.parameters.length < 32) {
            return false;
        }

        address externalNode = abi.decode(nodeDefinition.parameters, (address));
        if (!ERC165Helper.safeSupportsInterface(externalNode, type(IExternalNode).interfaceId)) {
            return false;
        }

        if (!IExternalNode(externalNode).isValid(nodeDefinition)) {
            return false;
        }

        return true;
    }
}
