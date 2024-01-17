// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract DropRandomiser is VRFConsumerBaseV2 {
    uint256 constant TOKEN_ID_MAX = 1890;
    uint256 REVEAL_DELAY = 48 * 60 * 60;

    mapping(address => bool) administrators;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256 revealTime;
        uint256 randomNumber;
    }

    mapping(uint256 => RequestStatus) s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256[] public requestIds;

    bytes32 keyHash;
    uint32 callbackGasLimit = 110000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    constructor(
        uint64 _subscriptionId,
        address _coordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_coordinator);
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        administrators[msg.sender] = true;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        external
        onlyAdmin
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomNumber: 0,
            exists: true,
            fulfilled: false,
            revealTime: block.timestamp + REVEAL_DELAY
        });
        requestIds.push(requestId);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomNumber =
            (_randomWords[0] % TOKEN_ID_MAX) +
            1;
    }

    function getRequestStatus(uint256 _requestId)
        public
        view
        returns (bool fulfilled, uint256 randomNumber)
    {
        RequestStatus memory request = s_requests[_requestId];
        require(request.exists, "request not found");
        require(
            block.timestamp > request.revealTime || isAdmin(),
            "Not yet revealed"
        );
        return (request.fulfilled, request.randomNumber);
    }

    function getAllRandomNumbers()
        public
        view
        onlyAdmin
        returns (uint256[] memory)
    {
        uint256[] memory allNumbers = new uint256[](requestIds.length);
        for (uint256 i = 0; i < requestIds.length; i++) {
            (, uint256 ranNum) = getRequestStatus(requestIds[i]);
            allNumbers[i] = ranNum;
        }
        return allNumbers;
    }

    // ==== ACCESS CONTROL ====

    modifier onlyAdmin() {
        require(isAdmin(), "Not admin");
        _;
    }

    function isAdmin() public view returns (bool) {
        return administrators[msg.sender];
    }

    function setAdmin(address _admin, bool _status) external onlyAdmin {
        administrators[_admin] = _status;
    }

    // ==== SETTERS ====

    function setDelay(uint256 _delay) external onlyAdmin {
        REVEAL_DELAY = _delay;
    }

    // ==== GETTERS ====

    function getRequests(uint256 _request)
        public
        view
        onlyAdmin
        returns (RequestStatus memory)
    {
        return s_requests[_request];
    }
}
