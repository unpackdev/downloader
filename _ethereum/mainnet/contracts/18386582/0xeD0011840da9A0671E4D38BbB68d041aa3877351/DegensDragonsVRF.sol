// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

/**
 * @title The RandomNumberGenerator contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */
contract DegensDragonsVRF is VRFConsumerBaseV2 {
    /// @notice Params for the request that will be written to the logs
    struct Params {
        string title;
    }

    VRFCoordinatorV2Interface immutable COORDINATOR;

    /// @notice Your subscription ID.
    uint64 private immutable _subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 private immutable _keyHash;

    /// @notice Callback gas limit must not go over 2.5M as required by VRF
    uint32 private constant CALLBACK_GAS_LIMIT = 2_500_000;

    /// @notice The default is 3, but you can set this higher.
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant NUM_WORDS = 1;

    /// @notice Address of the contract owner
    address private _owner;

    /// @notice The admin wallet that holds the unclaimed tokens.
    address private _administrator;

    /// @notice The requester contracts that will ask for random numbers.
    address[] private _requesters;

    // Array to track randomization requests
    mapping(uint256 => Params) public requests;

    event ReturnedRandomWord(
        uint256 randomWord,
        uint256 requestId,
        Params params
    );

    event RequesterAdded(address requester);
    event RequesterRemoved(address requester);

    error NewRequesterIsZeroAddress();
    error OnlyOwner();
    error OnlyOwnerOrRequester();

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param subscriptionId - the subscription ID that this contract uses for funding requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        _keyHash = keyHash;
        _owner = msg.sender;
        _subscriptionId = subscriptionId;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    /**
     * @notice Throws if called by any account other than the owner or requester contract.
     */
    modifier onlyOwnerOrRequester() virtual {
        if (msg.sender != _owner) {
            if (!requesterIsAdded(msg.sender)) {
                revert OnlyOwnerOrRequester();
            }
        }
        _;
    }

    function requesterIsAdded(address requester) public view returns (bool) {
        for (uint256 i = 0; i < _requesters.length; i++) {
            if (_requesters[i] == requester) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Add a requester contract to the admin array.
     *
     * @param requester The address of the requester.
     */
    function addRequester(address requester) external onlyOwner {
        if (requester == address(0)) {
            revert NewRequesterIsZeroAddress();
        }

        if (requesterIsAdded(requester)) {
            return;
        }

        _requesters.push(requester);
        emit RequesterAdded(requester);
    }

    /**
     * @notice Remove a requester contract from the admin array.
     *
     * @param requester The address of the requester.
     */
    function removeRequester(address requester) external onlyOwner {
        address[] storage requesters = _requesters;
        for (uint256 i = 0; i < requesters.length; i++) {
            if (requesters[i] == requester) {
                address last = requesters[requesters.length - 1];
                requesters[i] = last;
                requesters.pop();
                break;
            }
        }

        emit RequesterRemoved(requester);
    }

    /**
     * @notice Makes a random request
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     *
     * @param title the title used to write the logs
     */
    function requestRandomWords(
        string calldata title
    ) external onlyOwnerOrRequester {
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            _keyHash,
            _subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        requests[requestId] = Params(title);
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param requestId - the requestId from the VRF Coordinator
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        emit ReturnedRandomWord(randomWords[0], requestId, requests[requestId]);
    }

    /**
     * @notice Gets the subscription ID set up by VRF
     */
    function getSubscriptionId() public view returns (uint64) {
        return _subscriptionId;
    }
}
