// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./AccessControl.sol";
import "./ERC1155.sol";
import "./Strings.sol";
import "./IGrayBoys_Science_Lab.sol";

contract GrayBoys_Locker_Exchange is AccessControl, VRFConsumerBaseV2 {
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    bool public useVRF = true;

    uint16 constant numWords = 1;
    uint256 constant maxLockersToOpen = 50;

    /// @dev requestId => sender address
    mapping(uint256 => address) private requestIdToSender;

    uint256 private keyCardItemId = 2;
    uint256 private shardItemId = 4;
    uint256 private potionItemId = 5;
    uint256 private potionsToMint = 10;
    uint256 private requestNonce = 1;

    /// @notice Science labs implemented contract
    IGrayBoys_Science_Lab public labsContractAddress;

    /// @notice Track number of rares sent to not go over max
    uint256 public raresToSend = 7;

    /// @notice Lockers opened total
    uint256 public lockersOpened = 0;

    /// @notice locker index => is opened
    mapping(uint256 => bool) public lockerMapping;

    event RandomnessRequest(uint256 requestId);
    event ItemsMinted(address to, uint256 itemId, uint256 quantity);

    constructor(
        address _labsContractAddress,
        address _vrfV2Coordinator,
        bytes32 keyHash_,
        uint64 subscriptionId_
    ) VRFConsumerBaseV2(_vrfV2Coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfV2Coordinator);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        labsContractAddress = IGrayBoys_Science_Lab(_labsContractAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        _processRandomnessFulfillment(
            requestId,
            randomWords[0],
            requestIdToSender[requestId]
        );
    }

    /// @notice Opens a locker by id and burns a keycard token
    function open(uint256 lockerId) public {
        require(lockerId > 0 && lockerId < 51, "Invalid locker Id");
        require(!lockerMapping[lockerId], "Locker already opened");

        // Burn token to exchange
        labsContractAddress.burnMaterialForOwnerAddress(
            keyCardItemId,
            1,
            _msgSender()
        );

        uint256 requestId;

        if (useVRF == true) {
            requestId = COORDINATOR.requestRandomWords(
                _keyHash(),
                _subscriptionId(),
                3,
                300000,
                numWords
            );
            requestIdToSender[requestId] = _msgSender();
            _processRandomnessRequest(requestId, lockerId);
            emit RandomnessRequest(requestId);
        } else {
            requestId = requestNonce++;
            requestIdToSender[requestId] = _msgSender();
            _handleLockerUpdate(requestId, lockerId);
            _handleItemMinting(
                requestId,
                pseudorandom(_msgSender(), lockerId),
                _msgSender()
            );
        }
    }

    function readLockerState()
        public
        view
        returns (bool[maxLockersToOpen] memory)
    {
        bool[maxLockersToOpen] memory lockerState;
        for (uint256 i = 0; i < maxLockersToOpen; i++) {
            lockerState[i] = lockerMapping[i + 1];
        }
        return lockerState;
    }

    /// @dev Handle updating internal locker state
    function _handleLockerUpdate(uint256 requestId, uint256 lockerId) internal {
        lockerMapping[lockerId] = true;
        lockersOpened++;
    }

    /// @dev Handle minting items related to a randomness request
    function _handleItemMinting(
        uint256 requestId,
        uint256 randomness,
        address to
    ) internal {
        // Transform the result to a number between 1 and 50 inclusively
        uint256 chance = (randomness % 50) + 1;
        // Mint 1/1 of shard if chance or when we are at the end
        if (
            (chance < 8 && raresToSend > 0) ||
            (raresToSend > (maxLockersToOpen - lockersOpened))
        ) {
            labsContractAddress.mintMaterialToAddress(shardItemId, 1, to);
            emit ItemsMinted(to, shardItemId, 1);
            raresToSend--;
        } else {
            // Mint 10 potions
            labsContractAddress.mintMaterialToAddress(
                potionItemId,
                potionsToMint,
                to
            );
            emit ItemsMinted(to, potionItemId, potionsToMint);
        }
    }

    /// @dev Bastardized "randomness", if we want it
    function pseudorandom(address to, uint256 lockerId)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        to,
                        Strings.toString(requestNonce),
                        Strings.toString(lockerId)
                    )
                )
            );
    }

    /**
     * Chainlink integration
     */

    /// @dev Handle randomness request and process locker update
    function _processRandomnessRequest(uint256 requestId, uint256 lockerId)
        internal
    {
        _handleLockerUpdate(requestId, lockerId);
    }

    /// @dev Handles randomness fulfillment and processes mint logic
    function _processRandomnessFulfillment(
        uint256 requestId,
        uint256 randomness,
        address to
    ) internal {
        _handleItemMinting(requestId, randomness, to);
    }

    function _keyHash() internal view returns (bytes32) {
        return keyHash;
    }

    function _subscriptionId() internal view returns (uint64) {
        return subscriptionId;
    }

    /**
     * Owner functions
     */
    function setShardItemId(uint256 _shardItemId)
        external
        onlyRole(OWNER_ROLE)
    {
        shardItemId = _shardItemId;
    }

    function setPotionItemId(uint256 _potionItemId)
        external
        onlyRole(OWNER_ROLE)
    {
        potionItemId = _potionItemId;
    }

    function setKeyCardItemId(uint256 _keyCardItemId)
        external
        onlyRole(OWNER_ROLE)
    {
        keyCardItemId = _keyCardItemId;
    }

    function setPotionsToMint(uint256 _potionsToMint)
        external
        onlyRole(OWNER_ROLE)
    {
        potionsToMint = _potionsToMint;
    }

    function setLabsContractAddress(address _labsContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        labsContractAddress = IGrayBoys_Science_Lab(_labsContractAddress);
    }

    function setUseVRF(bool _useVRF) external onlyRole(OWNER_ROLE) {
        useVRF = _useVRF;
    }
}
