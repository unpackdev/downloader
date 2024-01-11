// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./AccessControl.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";
import "./IExternalItemSupport.sol";

contract UnifriendsVaultGame is AccessControl, VRFConsumerBaseV2 {
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    bool public useVRF = false;

    uint16 constant numWords = 1;
    uint256 constant maxLockersToOpen = 50;

    /// @dev requestId => sender address
    mapping(uint256 => address) private requestIdToSender;

    uint256 private vaultItemId = 4;
    uint256 private SUPER_RARE = 1;
    uint256 private RARE = 2;
    uint256 private COMMON = 3;
    uint256 private UNCOMMON = 4;
    uint256 private BASE = 5;
    uint256 private requestNonce = 1;

    /// @notice Unifriends item contract
    IExternalItemSupport public shopContractAddress;

    /// @notice Lockers opened total
    uint256 public lockersOpened = 0;

    /// @notice locker index => is opened
    mapping(uint256 => bool) public lockerMapping;

    event RandomnessRequest(uint256 requestId);
    event ItemsWon(address to, uint256 itemId, uint256 quantity);

    constructor(
        address _shopContractAddress,
        address _vrfV2Coordinator,
        bytes32 keyHash_,
        uint64 subscriptionId_
    ) VRFConsumerBaseV2(_vrfV2Coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfV2Coordinator);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        shopContractAddress = IExternalItemSupport(_shopContractAddress);
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
        require(!lockerMapping[lockerId], "Vault already opened");

        // Burn token to exchange
        shopContractAddress.burnItemForOwnerAddress(
            vaultItemId,
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
        // Transform the result to a number between 1 and 100 inclusively
        uint256 chance = (randomness % 100) + 1;

        // Superare 2%, rare 10%, common 20%, uncommon 30%, base 36%
        if (chance < 3) {
            // SUPER_RARE 1-2
            emit ItemsWon(to, SUPER_RARE, 1);
        } else if (chance >= 3 && chance < 14) {
            // RARE 3-13
            emit ItemsWon(to, RARE, 1);
        } else if (chance >= 14 && chance < 35) {
            // COMMON 14-34
            emit ItemsWon(to, COMMON, 1);
        } else if (chance >= 35 && chance < 66) {
            // UNCOMMON 35-65
            emit ItemsWon(to, UNCOMMON, 1);
        } else if (chance >= 66 && chance < 101) {
            // BASE 66-100
            emit ItemsWon(to, BASE, 1);
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
    function setVaultItemId(uint256 _vaultItemId)
        external
        onlyRole(OWNER_ROLE)
    {
        vaultItemId = _vaultItemId;
    }

    function setShopContractAddress(address _shopContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        shopContractAddress = IExternalItemSupport(_shopContractAddress);
    }

    function setUseVRF(bool _useVRF) external onlyRole(OWNER_ROLE) {
        useVRF = _useVRF;
    }
}
