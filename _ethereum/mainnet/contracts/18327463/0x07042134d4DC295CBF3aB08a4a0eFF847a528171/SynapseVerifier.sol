// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./ISynapseImpl.sol";

contract SynapseVerifier {
    address NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId,
        ISynapseImpl.SwapQuery calldata originQuery,
        ISynapseImpl.SwapQuery calldata destinationQuery
    ) external payable returns (ISynapseImpl.T2BRequest memory) {
        return
            ISynapseImpl.T2BRequest(amount, receiverAddress, toChainId, token);
    }

    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId,
        ISynapseImpl.SwapQuery calldata originQuery,
        ISynapseImpl.SwapQuery calldata destinationQuery
    ) external view returns (ISynapseImpl.T2BRequest memory) {
        return
            ISynapseImpl.T2BRequest(
                amount,
                receiverAddress,
                toChainId,
                NATIVE_TOKEN_ADDRESS
            );
    }
}
