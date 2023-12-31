// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./AxelarExecutable.sol";
import "./IAxelarGateway.sol";
import "./IAxelarExecutable.sol";

/**
 * @title Custom AxelarExecutable
 * @notice This is a copy of the AxelarExecutable contract with the following modifications
 * - instead of in the constructor, we set the gateway in the init function. This allows us to deploy
 *   with the same address on different chains that have different gateway addresses
 * - we bump up the solidity version to 0.8.19 to be consistent with the rest of the repository
 *
 * Source:
 * https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/65b50090851808057feb326bf6c8ce143d4cc086/contracts/executable/AxelarExecutable.sol#L10
 */
contract AxelarExecutableBase is IAxelarExecutable {
    IAxelarGateway public gateway;

    function _init(address _gateway) internal {
        if (_gateway == address(0)) revert InvalidAddress();
        gateway = IAxelarGateway(_gateway);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();

        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);

        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}
}
