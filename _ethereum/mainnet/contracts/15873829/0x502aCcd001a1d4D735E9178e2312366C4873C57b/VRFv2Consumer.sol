// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


contract DropRandomiser is VRFConsumerBaseV2 {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    uint256 constant TOKEN_ID_MAX = 1890;

    mapping(address => bool) administrators;


    struct RequestStatus {
        bool fulfilled; 
        bool exists; 
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    // bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15; // Goerli
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef; // Mainnet
    uint32 callbackGasLimit = 110000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    /**
     * ETHEREUM COORDINATOR: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
     * GOERLI COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
     */
    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909)
    {
        COORDINATOR = VRFCoordinatorV2Interface(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        s_subscriptionId = subscriptionId;
        administrators[msg.sender] = true;
    }


    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() external onlyAdmin returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords.push((_randomWords[0] % TOKEN_ID_MAX) + 1);

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId) public view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    // Access control

    modifier onlyAdmin {
        require(administrators[msg.sender], 'Not admin');
        _;
    }

    function setAdmin(address _admin, bool _status) external onlyAdmin {
        administrators[_admin] = _status;
    }

}
