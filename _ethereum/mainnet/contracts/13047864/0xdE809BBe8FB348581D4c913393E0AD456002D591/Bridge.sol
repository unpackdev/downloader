// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./Parameters.sol";
import "./ISmartPool.sol";

abstract contract Bridge is Parameters {
    mapping(bytes32 => bool) public queuedTransactions;

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes32) {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = true;

        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = false;
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes memory) {
        // reignDAO.execute already checks that the proposal is in grace period
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) =
            target.call{value: value}(callData);
        require(success, string(returnData));

        return returnData;
    }

    function updateWeights(uint256[] memory weights) internal {
        ISmartPool(smartPool).updateWeightsGradually(
            weights,
            block.number,
            block.number + gradualWeightUpdate // plus 2 days
        );
    }

    function applyAddToken() internal {
        ISmartPool(smartPool).applyAddToken();
    }

    function _getTxHash(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, eta));
    }
}
