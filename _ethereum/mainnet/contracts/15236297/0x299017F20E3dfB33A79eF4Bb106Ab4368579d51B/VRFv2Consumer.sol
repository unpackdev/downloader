// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract VRFv2Consumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // For coordinators on various networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    event RandomWordsOutput(uint256[] _randomWords);

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    mapping(address => bool) public authorizedToCall;

    constructor(
        uint64 subscriptionId,
        address _vrfCoordinator
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        authorizedToCall[msg.sender] = true;
    }

    function setCoordinator(address vrfCoordinator_) public onlyOwner {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
    }

    function setSubscriptionId(uint64 subscriptionId_) public onlyOwner {
        s_subscriptionId = subscriptionId_;
    }

    ////////////////////

    // requestConfirmations: The default is 3, but you can set this higher.

    // numWords: How many words to retrieve in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    // callbackGasLimit: Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(
        bytes32 keyHash,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external onlyAuthorized {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        emit RandomWordsOutput(randomWords);
        s_randomWords = randomWords;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorizedToCall[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        authorizedToCall[_toRemove] = false;
    }

    function getBytesFromUint256(uint256 target, uint8 numBytes) public pure returns (uint256) {
        return (target << numBytes) >> numBytes;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedToCall[msg.sender], 'a');
        _;
    }
}
