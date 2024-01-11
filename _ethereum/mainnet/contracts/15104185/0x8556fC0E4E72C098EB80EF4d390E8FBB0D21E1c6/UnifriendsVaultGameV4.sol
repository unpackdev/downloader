// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./AccessControl.sol";
import "./ERC1155Burnable.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./IExternalItemSupport.sol";

contract UnifriendsVaultGameV4 is AccessControl, VRFConsumerBaseV2 {
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    bool public isPaused = true;
    bool public useVRF = false;
    uint256 public prizesId = 1;
    uint256 public grandPrizesToSend = 1;
    uint256 public superRaresToSend = 2;
    uint256 public raresToSend = 6;
    uint256 public increasedRareOddsAfter = 35;

    uint16 constant numWords = 1;
    uint256 constant maxLockersToOpen = 50;
    uint256 constant maxGrandPrizes = 1;
    uint256 constant maxSuperRares = 2;
    uint256 constant maxRares = 4;

    /// @dev requestId => sender address
    mapping(uint256 => address) private requestIdToSender;

    uint256 private vaultItemId = 4;
    uint256 private GRAND_PRIZE = 1;
    uint256 private SUPER_RARE = 2;
    uint256 private RARE = 3;
    uint256 private COMMON = 4;
    uint256 private UNCOMMON = 5;
    uint256 private BASE = 6;
    uint256 private requestNonce = 1;

    /// @notice Unifriends item contract
    IExternalItemSupport public shopContractAddress;

    /// @notice Lockers opened total
    uint256 public lockersOpened = 0;

    /// @notice locker index => is opened
    mapping(uint256 => bool) public lockerMapping;

    event RandomnessRequest(uint256 requestId);

    event ItemsWon(
        uint256 prizesId,
        address to,
        uint256 itemId,
        uint256 quantity
    );

    event VaultReset(uint256 resetTimestamp);

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
        _setupRole(MODERATOR_ROLE, _msgSender());
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
        require(!isPaused, "Vault openings are paused");
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
        unchecked {
            lockersOpened++;
        }
    }

    /// @dev Handle minting items related to a randomness request
    function _handleItemMinting(
        uint256 requestId,
        uint256 randomness,
        address to
    ) internal {
        // Transform the result to a number between 1 and 100 inclusively
        uint256 chance = (randomness % 100) + 1;

        // Ensures at least 1 1 grand prize and 1 super rare will come out
        if (lockersOpened < increasedRareOddsAfter) {
            // Grand Prize 2%, Superare 5%, rare 8%, common 15%, uncommon 30%, base 40%
            if (
                grandPrizesToSend > 0 &&
                (chance < 3 ||
                    grandPrizesToSend >= (maxLockersToOpen - lockersOpened))
            ) {
                // GRAND_PRIZE 1-2
                emit ItemsWon(prizesId, to, GRAND_PRIZE, 1);
                unchecked {
                    grandPrizesToSend--;
                }
            } else if (
                superRaresToSend > 0 &&
                (chance < 9 ||
                    superRaresToSend >= (maxLockersToOpen - lockersOpened))
            ) {
                // SUPER_RARE 3-8 or 8% after grand prize
                emit ItemsWon(prizesId, to, SUPER_RARE, 1);
                unchecked {
                    superRaresToSend--;
                }
            } else if (raresToSend > 0 && (chance >= 9 && chance < 18)) {
                // RARE 9-17
                emit ItemsWon(prizesId, to, RARE, 1);
                unchecked {
                    raresToSend--;
                }
            } else if (chance < 31) {
                // UNCOMMON 18-30
                emit ItemsWon(prizesId, to, COMMON, 1);
            } else if (chance < 61) {
                // COMMON 31-60
                emit ItemsWon(prizesId, to, UNCOMMON, 1);
            } else {
                // BASE 60-100
                emit ItemsWon(prizesId, to, BASE, 1);
            }
        } else {
            // Increased odds
            // Grand Prize 10%, Superare 10%, rare 10%, common 20%, uncommon 20%, base 20%
            // rare 30% if both big prizes gone
            if (
                grandPrizesToSend > 0 &&
                (chance < 10 ||
                    (grandPrizesToSend >= (maxLockersToOpen - lockersOpened)))
            ) {
                // GRAND PRIZE 1-9
                emit ItemsWon(prizesId, to, GRAND_PRIZE, 1);
                unchecked {
                    grandPrizesToSend--;
                }
            } else if (
                superRaresToSend > 0 &&
                ((chance >= 10 && chance < 20) ||
                    (superRaresToSend >= (maxLockersToOpen - lockersOpened)))
            ) {
                // SUPER RARE 10-19
                emit ItemsWon(prizesId, to, SUPER_RARE, 1);
                unchecked {
                    superRaresToSend--;
                }
            } else if (raresToSend > 0 && chance < 30) {
                // RARE 20-29
                emit ItemsWon(prizesId, to, RARE, 1);
                unchecked {
                    raresToSend--;
                }
            } else if ((chance >= 30 && chance < 50)) {
                // UNCOMMON 30-49
                emit ItemsWon(prizesId, to, COMMON, 1);
            } else if (chance < 70) {
                // COMMON 50-70
                emit ItemsWon(prizesId, to, UNCOMMON, 1);
            } else {
                // BASE 70-100
                emit ItemsWon(prizesId, to, BASE, 1);
            }
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
     * Moderator functions
     */
    /// @dev Handles resetting the vault
    function resetVault() public onlyRole(MODERATOR_ROLE) {
        for (uint256 i = 0; i < maxLockersToOpen; i++) {
            lockerMapping[i + 1] = false;
        }
        lockersOpened = 0;
        raresToSend = maxRares;
        superRaresToSend = maxSuperRares;
        grandPrizesToSend = maxGrandPrizes;
        emit VaultReset(block.timestamp);
    }

    /// @dev Handles changing up when increased odds should happen
    function setIncreasedRareOddsAfter(uint256 _increasedRareOddsAfter)
        external
        onlyRole(MODERATOR_ROLE)
    {
        increasedRareOddsAfter = _increasedRareOddsAfter;
    }

    /// @dev Handles changing up the prize set
    function setPrizesId(uint256 _prizesId) external onlyRole(MODERATOR_ROLE) {
        prizesId = _prizesId;
    }

    /// @dev Handles changing up the max grand prizes to send
    function setMaxGrandPrizes(uint256 _grandPrizesToSend)
        external
        onlyRole(MODERATOR_ROLE)
    {
        grandPrizesToSend = _grandPrizesToSend;
    }

    /// @dev Handles changing up the max super rare prizes to send
    function setMaxSuperRares(uint256 _superRaresToSend)
        external
        onlyRole(MODERATOR_ROLE)
    {
        superRaresToSend = _superRaresToSend;
    }

    /// @dev Handles changing up the max rare prizes to send
    function setMaxRares(uint256 _raresToSend)
        external
        onlyRole(MODERATOR_ROLE)
    {
        raresToSend = _raresToSend;
    }

    /// @dev Sets the vault burn item id
    function setVaultItemId(uint256 _vaultItemId)
        external
        onlyRole(MODERATOR_ROLE)
    {
        vaultItemId = _vaultItemId;
    }

    /// @dev Determines whether to allow openings at all
    function setPaused(bool _isPaused) external onlyRole(MODERATOR_ROLE) {
        isPaused = _isPaused;
    }

    /**
     * Owner functions
     */

    /// @dev Sets the contract address for the item to burn
    function setShopContractAddress(address _shopContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        shopContractAddress = IExternalItemSupport(_shopContractAddress);
    }

    /// @dev Determines whether to use VRF or not
    function setUseVRF(bool _useVRF) external onlyRole(OWNER_ROLE) {
        useVRF = _useVRF;
    }
}
