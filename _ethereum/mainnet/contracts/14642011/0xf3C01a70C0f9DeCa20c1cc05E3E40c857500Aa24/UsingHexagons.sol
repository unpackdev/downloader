//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Constants.sol";
import "./Errors.sol";

/**
 * @title UsingHexagons
 *
 * @notice This is the contract that should be used by all those contracts that
 *         want to interact with Hexagons protocol. This protocol is composed of a series
 *         of relayers who are authorized to interact with a contract
 *         through the use of the sendHexagonsProtocolMessage function.
 */
contract UsingHexagons is Ownable {
    mapping(address => bool) public lensProtocolModules;
    mapping(bytes32 => bool) private processedMessages;

    /**
     * @notice Function used allows a Lens Protocol module to receive messages
     *
     * @param _lensProtocolModule LensProtocolModule address
     */
    function addLensProtocolModule(address _lensProtocolModule) external onlyOwner {
        lensProtocolModules[_lensProtocolModule] = true;
    }

    /**
     * @notice Function called by the relayers to send a message to this contract.
     *
     * @param _protocolId Protocol identifier (Lens Protocol, Twitter ecc ecc)
     * @param _queryId Unique identifier
     * @param _author Address of the author that triggered a message
     * @param _data Message data
     * @param _proof Cryptographic proof that indicates the authenticity of a certain message
     */
    function sendHexagonsProtocolMessage(
        uint256 _protocolId,
        bytes32 _queryId,
        address _author,
        bytes calldata _data,
        bytes calldata _proof
    ) public {
        bytes32 messageId = keccak256(abi.encode(_protocolId, _queryId));
        if (processedMessages[messageId]) revert Errors.RequestAlreadyProcessed();
        if (!_verify(_protocolId, _proof)) revert Errors.InvalidProof();
        _onHexagonsProtocolMessage(_protocolId, _author, _data);
        processedMessages[messageId] = true;
    }

    /**
     * @notice Function that should be implemented within the contract that extends UsingHexagons
     *
     * @param _protocolId Protocol identifier
     * @param _author Address of the author that triggered a message
     * @param _data Message data
     */
    function _onHexagonsProtocolMessage(
        uint256 _protocolId,
        address _author,
        bytes calldata _data
    ) internal virtual {}

    /**
     * @notice Function used by this contract to verify a sent by a relay.
     * @param _protocolId Protocol identifier
     * @param _proof Cryptographic proof that indicates the authenticity of a certain message
     */
    function _verify(uint256 _protocolId, bytes calldata _proof) private view returns (bool) {
        if (_protocolId == Constants.PROTOCOL_LENS && lensProtocolModules[msg.sender]) {
            return true;
        }
        // TODO: verify the proof here ...
        return true;
    }
}
