// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

/**
 * @title The RandomNumberConsumerV2 contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */
contract RandomNumberConsumerV2 is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface internal COORDINATOR;
    LinkTokenInterface internal LINK_TOKEN;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable s_keyHash;

    // Your subscription ID.
    uint64 public s_subscriptionId;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 immutable s_callbackGasLimit = 600000;

    // The default is 3, but you can set this higher.
    uint16 immutable s_requestConfirmations = 3;

    mapping(string => uint256) private s_requestKeyToRequestId;
    mapping(uint256 => uint256) private s_requestIdToRequestIndex;
    mapping(uint256 => uint256[]) internal s_requestIndexToRandomWords;
//    uint256[] public s_randomWords;
//    uint256 public s_requestId;

    address s_owner;

    uint256 public requestCounter;

    event ReturnedRandomness(uint256[] randomWords);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param link - contract address of LINK token
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        address vrfCoordinator,
        address link,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
//        VRFCoordinatorV2Interface tempCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
//        uint64 subscriptionId = tempCoordinator.createSubscription();
//        tempCoordinator.addConsumer(subscriptionId, address(this));
//        LINK_TOKEN = LinkTokenInterface(link);
//        COORDINATOR = tempCoordinator;
//        s_subscriptionId = subscriptionId;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINK_TOKEN = LinkTokenInterface(link);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        createNewSubscription();
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function createNewSubscription() private onlyOwner {
        // Create a subscription with a new subscription ID.
        address[] memory consumers = new address[](1);
        consumers[0] = address(this);
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumers[0]);
    }

    function isVRFContract() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Requests randomness
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     *
     * @param _requestKey - key of the request
     * @param _numWords - length of array of random results from VRF Coordinator
     */
    function requestRandomWords(string memory _requestKey, uint32 _numWords) external onlyOwner {
        require(s_requestKeyToRequestId[_requestKey] == 0, "RequestKey already used");
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            _numWords
        );
        s_requestKeyToRequestId[_requestKey] = requestId;
        s_requestIdToRequestIndex[requestId] = requestCounter;
        requestCounter += 1;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param _requestId - id of the request
     * @param _randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 requestIndex = s_requestIdToRequestIndex[_requestId];
        s_requestIndexToRandomWords[requestIndex] = _randomWords;
        emit ReturnedRandomness(_randomWords);
    }

    function cancelSubscription() external {
        COORDINATOR.cancelSubscription(s_subscriptionId, msg.sender);
    }

    function fund(uint96 _amount) public {
        LINK_TOKEN.transferAndCall(
            address(COORDINATOR),
            _amount,
            abi.encode(s_subscriptionId)
        );
    }

    function hasRequestKey(string memory _requestKey) public view returns (bool) {
        return s_requestKeyToRequestId[_requestKey] != 0;
    }

    function getRequestId(string memory _requestKey) public view returns (uint256) {
        return s_requestKeyToRequestId[_requestKey];
    }

    function getRandomWords(string memory _requestKey) public view returns (uint256[] memory) {
        require(hasRequestKey(_requestKey), "Didn't request using the requestKey");
        uint256 requestIndex = s_requestIdToRequestIndex[s_requestKeyToRequestId[_requestKey]];
        require(s_requestIndexToRandomWords[requestIndex].length != 0, "not yet");
        return s_requestIndexToRandomWords[requestIndex];
    }
}
