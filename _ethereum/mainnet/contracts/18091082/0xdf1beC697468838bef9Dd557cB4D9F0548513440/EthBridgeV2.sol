// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";


contract EthBridgeV2 is OwnableUpgradeable, PausableUpgradeable {

    struct Vesting {
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    struct VestingSlot {
        uint256 startTime;
        uint256 vestingDuration;
    }

    /// @notice Address of LuckyBlock V2 token.
    IERC20Upgradeable public luckyBlockV2;

    /// @notice Total vesting slots created by owner.
    uint256 public totalVestingSlots;

    /// @notice Maps Vesting Slot Id to Vesting Slot Details.
    mapping(uint256 => VestingSlot) public vestingSlots;

    /// @notice Maps User address => (Vesting Slot Id => Vesting Details)
    mapping(address => mapping(uint256 => Vesting)) public vestings;

    /// @notice Maps User address => (Vesting Slot Id => Is Blacklisted Boolean)
    mapping(address => mapping(uint256 => bool)) public isBlacklisted;

    event VestingSlotCreated(
        address indexed by,
        uint256 indexed slotId,
        uint256 startTime,
        uint256 vestingDuration,
        uint256 timestamp
    );

    event VestingSlotUpdated(
        address indexed by,
        uint256 indexed slotId,
        uint256 startTime,
        uint256 vestingDuration,
        uint256 timestamp
    );

    event VestingsCreated(
        address indexed by,
        uint256 indexed vestingSlotId,
        address[] users,
        uint256[] amounts,
        uint256 timestamp
    );

    event VestingsUpdated(
        address indexed by,
        uint256 indexed vestingSlotId,
        address[] users,
        uint256[] amounts,
        uint256 timestamp
    );

    event TokensClaimed(
        address indexed by,
        uint256 indexed vestingSlotId,
        uint256 claimedAmount,
        uint256 timestamp
    );

    event UsersAddedToBlacklist(
        address indexed by,
        uint256 indexed slotId,
        address[] users,
        uint256 timestamp
    );

    event UsersRemovedFromBlacklist(
        address indexed by,
        uint256 indexed slotId,
        address[] users,
        uint256 timestamp
    );

    /** Custom Errors */
    error ZeroAddress();
    error VestingStartTimeInPast(uint256 startTime, uint256 currentTime);
    error VestingDurationCannotBeZero();
    error InvalidVestingSlotId();
    error ArrayLengthMismatch(uint256 usersArrayLength, uint256 amountsArrayLength);
    error VestingExists(uint256 slotId, address user);
    error VestingDoesNotExist(uint256 slotId, address user);
    error NoClaimAvailable(uint256 slotId, address user);
    error ClaimBeforeVestingStart(uint256 slotId, uint256 startTime, uint256 currentTime);
    error ErrorInTokenTransfer(address from, address to, uint256 amount);
    error BlacklistedFromClaiming();
    error CannotUpdateActiveSlot();
    error CannotUpdateActiveSlotVestings();


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /**
     * @notice Function to initialize the proxy contract with ownership and luckyBlockV2 token address.
     * @param _luckyBlockV2Token Address of the LuckyBlockV2 token contract.
     */
    function initialize(address _luckyBlockV2Token) external initializer {
        if(_luckyBlockV2Token == address(0)) revert ZeroAddress();
        __Ownable_init();
        __Pausable_init();
        luckyBlockV2 = IERC20Upgradeable(_luckyBlockV2Token);
    }


    /**
     * @notice Function for owner to create a new vesting slot.
     * @param _vestingStartTime Time in epoch, at which vestings created in this slot will start.
     * @param _vestingDuration Duration in epoch, for all vestings created in this slot.
     */
    function createVestingSlot(
        uint256 _vestingStartTime,
        uint256 _vestingDuration
    ) external onlyOwner {
        if(block.timestamp > _vestingStartTime) revert VestingStartTimeInPast(_vestingStartTime, block.timestamp);
        if(_vestingDuration == 0) revert VestingDurationCannotBeZero();
        uint256 slotId;
        unchecked { slotId = ++totalVestingSlots; }
        vestingSlots[slotId] = VestingSlot(
            _vestingStartTime,
            _vestingDuration
        );
        emit VestingSlotCreated(
            msg.sender,
            slotId,
            _vestingStartTime,
            _vestingDuration,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner to update an existing vesting slot.
     * @param _slotId Id of the vesting slot to update.
     * @param _vestingStartTime Time in epoch, at which vestings created in this slot will start.
     * @param _vestingDuration Duration in epoch, for all vestings created in this slot.
     */
    function updateVestingSlot(
        uint256 _slotId,
        uint256 _vestingStartTime,
        uint256 _vestingDuration
    ) external onlyOwner {
        if(_slotId == 0 || _slotId > totalVestingSlots) revert InvalidVestingSlotId();
        if(_vestingDuration == 0) revert VestingDurationCannotBeZero();
        VestingSlot storage slot = vestingSlots[_slotId];
        if(block.timestamp >= slot.startTime) revert CannotUpdateActiveSlot();
        if(block.timestamp > _vestingStartTime) revert VestingStartTimeInPast(_vestingStartTime, block.timestamp);
        slot.startTime = _vestingStartTime;
        slot.vestingDuration = _vestingDuration;
        
        emit VestingSlotUpdated(
            msg.sender,
            _slotId,
            _vestingStartTime,
            _vestingDuration,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner to create vestings for users.
     * @param _vestingSlotId Id of the vesting slot in which to create user vestings.
     * @param _users Array of user addresses for whom to create vestings.
     * @param _amounts Array of token amounts to be vested for addresses in the _users array. 
     */
    function createVestings(
        uint256 _vestingSlotId,
        address[] calldata _users,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if(_vestingSlotId == 0 || _vestingSlotId > totalVestingSlots) revert InvalidVestingSlotId();
        if(_users.length != _amounts.length) revert ArrayLengthMismatch(_users.length, _amounts.length);

        for(uint256 i; i<_users.length;) {
            // Vesting for user in this slot should not already exist.
            Vesting storage vesting = vestings[_users[i]][_vestingSlotId];
            if(vesting.totalAmount != 0) revert VestingExists(_vestingSlotId, _users[i]);
            vesting.totalAmount = _amounts[i];
            unchecked { ++i; }
        }

        emit VestingsCreated(
            msg.sender,
            _vestingSlotId,
            _users,
            _amounts,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner to update existing vestings for users, if vesting slot not started.
     * @param _vestingSlotId Id of the vesting slot in which to update user vestings.
     * @param _users Array of user addresses for whom to update vestings.
     * @param _amounts Array of updated token amounts to be vested for addresses in the _users array. 
     */
    function updateVestings(
        uint256 _vestingSlotId,
        address[] calldata _users,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if(_vestingSlotId == 0 || _vestingSlotId > totalVestingSlots) revert InvalidVestingSlotId();
        if(_users.length != _amounts.length) revert ArrayLengthMismatch(_users.length, _amounts.length);
        if(block.timestamp >= vestingSlots[_vestingSlotId].startTime) revert CannotUpdateActiveSlotVestings();

        for(uint256 i; i<_users.length;) {
            // Vesting for user in this slot should already exist.
            Vesting storage vesting = vestings[_users[i]][_vestingSlotId];
            if(vesting.totalAmount == 0) revert VestingDoesNotExist(_vestingSlotId, _users[i]);
            vesting.totalAmount = _amounts[i];
            unchecked { ++i; }
        }

        emit VestingsUpdated(
            msg.sender,
            _vestingSlotId,
            _users,
            _amounts,
            block.timestamp
        );
    }


    /**
     * @notice Function for users to claim vested tokens.
     * @param _vestingSlot Id of the vesting slot from which user wants to claim vested tokens.
     */
    function claimTokens(uint256 _vestingSlot) external whenNotPaused {
        if(isBlacklisted[msg.sender][_vestingSlot]) revert BlacklistedFromClaiming();
        Vesting storage vesting = vestings[msg.sender][_vestingSlot];
        if(vesting.claimedAmount == vesting.totalAmount) revert NoClaimAvailable(_vestingSlot, msg.sender);
        if(block.timestamp < vestingSlots[_vestingSlot].startTime) 
            revert ClaimBeforeVestingStart(_vestingSlot, vestingSlots[_vestingSlot].startTime, block.timestamp);

        uint256 claimAmount = getClaimableAmount(msg.sender, _vestingSlot);
        unchecked { vesting.claimedAmount = vesting.claimedAmount + claimAmount; }

        if(! luckyBlockV2.transfer(msg.sender, claimAmount))
            revert ErrorInTokenTransfer(address(this), msg.sender, claimAmount);
            
        emit TokensClaimed(
            msg.sender,
            _vestingSlot,
            claimAmount,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner to pause the contract, affects bridgeTokens function.
     */
    function pause() external onlyOwner {
        _pause();
    }


    /**
     * @notice Function for owner to unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }


    /**
     * @notice Function for owner to add users to blacklist for a particular slot to stop them from claiming.
     * @param _slotId Id of the vesting slot for which to blacklist users.
     * @param _users Array of addresses of the users to be blacklisted.
     */
    function addToBlacklist(uint256 _slotId, address[] calldata _users) external onlyOwner {
        if(_slotId == 0 || _slotId > totalVestingSlots) revert InvalidVestingSlotId();
        for(uint256 i=0; i<_users.length;) {
            isBlacklisted[_users[i]][_slotId] = true;
            unchecked { ++i; }
        }
        emit UsersAddedToBlacklist(
            msg.sender,
            _slotId,
            _users,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner to remove users from blacklist of a particular slot to allow them to claim.
     * @param _slotId Id of the vesting slot in which to remove users from blacklist.
     * @param _users Array of addresses of the users to be removed from blacklist.
     */
    function removeFromBlacklist(uint256 _slotId, address[] calldata _users) external onlyOwner {
        if(_slotId == 0 || _slotId > totalVestingSlots) revert InvalidVestingSlotId();
        for(uint256 i=0; i<_users.length;) {
            isBlacklisted[_users[i]][_slotId] = false;
            unchecked { ++i; }
        }
        emit UsersRemovedFromBlacklist(
            msg.sender,
            _slotId,
            _users,
            block.timestamp
        );
    }


    /**
     * @notice Function to get token amount available to be claimed for an user in a vesting slot.
     * @param _address User address for which to get claimable amount.
     * @param _slotId Vesting slot id for which to get the claimable amount.
     */
    function getClaimableAmount(
        address _address,
        uint256 _slotId
    ) public view returns(uint256) {
        VestingSlot memory slot = vestingSlots[_slotId];
        Vesting memory vesting = vestings[_address][_slotId];

        if (block.timestamp <= slot.startTime) return 0;
         /**
         @dev 
         * Claim time = If (current time >= Vesting Start Time + Duration) => Vesting Duration 
                        else Current time - Vesting Start Time
         * Vested Amount = ((Claim Time * Total Amount) / Vesting Duration
         * Claim Amount Available = Vested Amount - Already Claimed amount
         */
        uint256 claimTime = block.timestamp >= slot.startTime + slot.vestingDuration ?
            slot.vestingDuration :
            block.timestamp - slot.startTime;
        return (
            (claimTime * vesting.totalAmount) / slot.vestingDuration
        ) - vesting.claimedAmount;
    }
}
