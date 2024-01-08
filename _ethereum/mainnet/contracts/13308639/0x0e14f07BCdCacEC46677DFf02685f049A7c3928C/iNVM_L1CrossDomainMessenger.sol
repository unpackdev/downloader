// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import "./Lib_NVMCodec.sol";

/* Interface Imports */
import "./iNVM_CrossDomainMessenger.sol";

/**
 * @title iNVM_L1CrossDomainMessenger
 */
interface iNVM_L1CrossDomainMessenger is iNVM_CrossDomainMessenger {

    /*******************
     * Data Structures *
     *******************/

    struct L2MessageInclusionProof {
        bytes32 stateRoot;
        bytes stateTrieWitness;
        bytes storageTrieWitness;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Relays a cross domain message to a contract.
     * @param _target Target contract address.
     * @param _sender Message sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     * @param _ovmTransaction OVM transaction.
     * @param _proof Inclusion proof for the given message.
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        Lib_NVMCodec.Transaction memory _ovmTransaction,
        Lib_NVMCodec.Receipt memory _receipt,
        L2MessageInclusionProof memory _proof
    ) external;

    /**
     * Replays a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _sender Original sender address.
     * @param _message Message to send to the target.
     * @param _queueIndex CTC Queue index for the message to replay.
     * @param _gasLimit Gas limit for the provided message.
     */
    function replayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _queueIndex,
        uint32 _gasLimit
    ) external;
}
