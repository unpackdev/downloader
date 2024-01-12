//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./console.sol";

contract Lottery is VRFConsumerBaseV2 {
    bool private requestInProgress = false;

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 public subscriptionId;

    address public vrfCoordinator;

    bytes32 public keyHash;

    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    address public owner;

    string public PLAYERS_PROVENANCE;

    string public PLAYERS_LIST_URL;

    uint64 public PLAYERS_LIST_SIZE;

    event PlayersProvenanceHashSet(string _provenanceHash);

    event PlayersListUrlSet(string _url);

    event PlayersListSizeSet(uint64 _size);

    event RandomRequested(uint256 indexed requestId);

    event RandomIndex(uint256 indexed requestId, uint256 indexed result);

    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        owner = msg.sender;
        subscriptionId = _subscriptionId;
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
    }

    function setPlayersProvenanceHash(string calldata _provenanceHash)
        external
        onlyOwner
    {
        PLAYERS_PROVENANCE = _provenanceHash;
        emit PlayersProvenanceHashSet(_provenanceHash);
    }

    function setPlayersListUrl(string calldata _url) external onlyOwner {
        PLAYERS_LIST_URL = _url;
        emit PlayersListUrlSet(_url);
    }

    function setPlayersListSize(uint64 _size) external onlyOwner {
        PLAYERS_LIST_SIZE = _size;
        emit PlayersListSizeSet(_size);
    }

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        require(!requestInProgress, "Request is in progress");
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestInProgress = true;
        emit RandomRequested(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // transform the result to a number between 1 and 9999 inclusively
        uint256 result = (randomWords[0] % PLAYERS_LIST_SIZE) + 1;
        requestInProgress = false;
        emit RandomIndex(requestId, result);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner error");
        _;
    }
}
