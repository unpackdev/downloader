// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

/// @title EtherealStatesVRFUpdated
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, dievardump@gmail.com)
/// @notice EtherealStates VRF logic
contract EtherealStatesVRFUpdated is VRFConsumerBaseV2 {
    struct VRFConfig {
        bytes32 keyHash;
        address coordinator;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
    }

    /// @notice ChainLink request id
    uint256 public requestId;

    /// @notice ChainLink config
    VRFConfig public vrfConfig;

    constructor(VRFConfig memory vrfConfig_)
        VRFConsumerBaseV2(vrfConfig_.coordinator)
    {
        vrfConfig = vrfConfig_;
    }

    /// @dev basic call using the vrfConfig
    function _requestRandomWords()
        internal
        virtual
        returns (uint256 requestId_)
    {
        VRFConfig memory vrfConfig_ = vrfConfig;
        // Will revert if subscription is not set and funded.
        requestId_ = VRFCoordinatorV2Interface(vrfConfig_.coordinator)
            .requestRandomWords(
                vrfConfig_.keyHash,
                vrfConfig_.subscriptionId,
                vrfConfig_.requestConfirmations,
                vrfConfig_.callbackGasLimit,
                vrfConfig_.numWords
            );

        requestId = requestId_;
    }

    /// @dev needs to be overrode in the consumer contract
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory
    ) internal virtual override {}
}
