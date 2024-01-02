// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import "./Relayer.sol";
import "./Governor.sol";
import "./Storage.sol";
import "./IZkSync.sol";
import "./ERC721Checkpointable.sol";
import "./Base.sol";

/**
 * @title Nouns Relayer
 * @author Federation - https://x.com/FederationWTF
 */
contract NounsRelayer is Relayer {
    /// The proposals that have been relayed
    mapping(uint256 => bool) public relayed;

    /**
     * @notice Initialize the contract
     * @param _data The encoded data containing the config
     */
    function init(bytes calldata _data) external payable initializer {
        (Config memory _config, MotivatorConfig memory _motivatorConfig) = abi
            .decode(_data, (Config, MotivatorConfig));

        config = _config;
        motivatorConfig = _motivatorConfig;

        if (msg.sender != _config.base) {
            _transferOwnership(_config.base);
        }
    }

    /**
     * @notice Relay proposal outcome from the L2 to the DAO
     * @param _l1BatchNumber The L1 batch number the message was sent on
     * @param _index The message index
     * @param _l1BatchTxIndex The L1 batch transaction index the message was sent on
     * @param _message The encoded message
     * @param _messageProof The generated proof of the message
     */
    function relayVotes(
        uint256 _l1BatchNumber,
        uint256 _index,
        uint16 _l1BatchTxIndex,
        bytes calldata _message,
        bytes32[] calldata _messageProof
    ) external refundGas {
        IZkSync zksync = IZkSync(config.zkSync);

        L2Message memory encodedMessage = L2Message({
            sender: config.governor,
            data: _message,
            txNumberInBlock: _l1BatchTxIndex
        });

        bool success = zksync.proveL2MessageInclusion(
            _l1BatchNumber,
            _index,
            encodedMessage,
            _messageProof
        );

        if (!success) revert InvalidMessageProof();

        Governor.Message memory message = abi.decode(
            _message,
            (Governor.Message)
        );

        if (relayed[message.proposal]) revert AlreadyRelayed();

        uint256 totalVotes = ERC721Checkpointable(config.nativeToken)
            .totalSupply();
        uint256 totalVotesCast = message.forVotes +
            message.againstVotes +
            message.abstainVotes;

        if (totalVotesCast < (totalVotes * config.quorumVotesBPS) / 10000) {
            revert QuorumNotMet();
        }

        // 0=against, 1=for, 2=abstain
        uint8 support = 2;

        if (
            message.againstVotes >= message.forVotes &&
            message.againstVotes >= message.abstainVotes
        ) {
            support = 0;
        }

        if (
            message.forVotes >= message.againstVotes &&
            message.forVotes >= message.abstainVotes
        ) {
            support = 1;
        }

        Base(payable(config.base)).execute(
            config.externalDAO,
            0,
            abi.encodeWithSignature(
                "castRefundableVote(uint256,uint8)",
                message.proposal,
                support
            )
        );

        relayed[message.proposal] = true;

        _tip();

        emit VotesRelayed(
            message.proposal,
            support,
            totalVotes,
            totalVotesCast
        );
    }
}
