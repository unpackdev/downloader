// SPDX-License-Identifier: MIT

/// @title RARE Pass Giveaway
/// @notice contract to select winners that can get RARE Passes airdropped to them
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import "VRFConsumerBaseV2.sol";
import "VRFCoordinatorV2Interface.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract RAREPassGiveaway is VRFConsumerBaseV2, Ownable {

    // state variables
    bytes32 private _keyHash;
    uint64 private _subscriptionId;
    uint16 private _requestConfirmations;
    uint32 private _callbackGasLimit;
    uint32 private _numWords;
    uint256[] private _randomWords;

    VRFCoordinatorV2Interface public coordinator;

    bytes32 public merkleRoot;
    mapping(address => bool) private _hasEntered;
    address[] private _entries;
    
    // events
    event Enter(address indexed user);
    event RandomnessFulfilled(uint256 indexed requestId);
    event Winner(address indexed winner);

    constructor(
        bytes32 keyHash,
        uint64 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address vrfCoordinator,
        bytes32 root
    )
    VRFConsumerBaseV2(vrfCoordinator)
    Ownable()
    {
        _keyHash = keyHash;
        _subscriptionId = subscriptionId;
        _requestConfirmations = requestConfirmations;
        _callbackGasLimit = callbackGasLimit;
        _numWords = numWords;
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        merkleRoot = root;
    }

    /// @notice function to set merkle root
    /// @dev requires contract owner
    /// @dev only needed if the merkle root is calculted wrong or addresses were missed
    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    /// @notice function for allowlisted people to sign up for the giveaway
    /// @dev requires person to submit a merkle proof and be on the allowlist
    function enter(bytes32[] calldata merkleProof) external {
        require(!_hasEntered[msg.sender], "msg.sender has already entered the raffle");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "not on the allowlist");

        _entries.push(msg.sender);
        _hasEntered[msg.sender] = true;

        emit Enter(msg.sender);
    }

    /// @notice function to set keyHash
    /// @dev requires contract owner
    function setKeyHash(bytes32 newKeyHash) external onlyOwner {
        _keyHash = newKeyHash;
    }

    /// @notice function to set subscriptionId
    /// @dev requires contract owner
    function setSubscriptionId(uint64 newSubscriptionId) external onlyOwner {
        _subscriptionId = newSubscriptionId;
    }

    /// @notice function to set requestConfirmations
    /// @dev requires contract owner
    function setRequestConfirmations(uint16 newRequestConfirmations) external onlyOwner {
        _requestConfirmations = newRequestConfirmations;
    }

    /// @notice function to set callbackGasLimit
    /// @dev requires contract owner
    function setCallbackGasLimit(uint32 newCallbackGasLimit) external onlyOwner {
        _callbackGasLimit = newCallbackGasLimit;
    }

    /// @notice function to set numWords
    /// @dev requires contract owner
    function setNumWords(uint32 newNumWords) external onlyOwner {
        _numWords = newNumWords;
    }

    /// @notice function to request randomness from the coordinator
    /// @dev requires contract owner
    /// @dev should not be called multiple times unless something goes wrong
    function requestRandomness() external onlyOwner {
        coordinator.requestRandomWords(
            _keyHash,
            _subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );
    }

    /// @notice function to select the winners
    /// @dev requires contract owner
    /// @dev should only be called after randomness has been fulfilled
    /// @dev does not check if there are enough entries based on number of random words requested.
    ///      This is left up to the user/owner of the contract to decide.
    function selectWinners() external onlyOwner {
        uint256 numWinners = _randomWords.length;
        // loop through number of randomWords and select winners 
        for (uint256 i = 0; i < numWinners; i++) {
            uint256 winningIndex = _getRandomIndex(_randomWords[i], _entries.length);
            address winner = _entries[winningIndex];

            _entries[winningIndex] = _entries[_entries.length - 1];
            _entries.pop();

            emit Winner(winner);
        }
    }

    /// @notice function to view if an address has entered the raffle
    function hasEntered(address user) external view returns(bool) {
        return _hasEntered[user];
    }

    /// @notice function override for fulfilling random words
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        _randomWords = randomWords;

        emit RandomnessFulfilled(requestId);
    }

    /// @notice function to get random index from random word supplied from VRF
    /// @dev modulo bias is insignificant for entries less than 100 billion
    function _getRandomIndex(uint256 randomWord, uint256 maxIndex) internal pure returns(uint256) {
        return randomWord % maxIndex;
    }
}