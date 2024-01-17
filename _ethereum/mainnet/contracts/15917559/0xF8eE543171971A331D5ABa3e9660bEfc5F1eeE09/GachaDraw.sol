// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IAnimeMetaverseTicket.sol";
import "./IAnimeMetaverseReward.sol";

/// @notice Should have sufficient reward for gacha activity
/// @dev Use this custom error on revert function whenever there is insufficiant reward
error InsufficientReward();

/// @notice Should provide a valid activity Id for any gacha activity
/// @dev Use this custom error on revert function whenever invalid activity Id
error InvalidActivity();

/// @notice Should provide a valid activity type either FREE_ACTIVITY_TYPE or PREMIUM_ACTIVITY_TYPE
/// @dev Use this custom error on revert function whenever the activity type is not valid
error InvalidActivityType();

/// @notice Should draw ticket for a active gacha activity
/// @dev Use this custom error on revert function the activity is not active
error InactiveActivity();

/// @notice Should draw ticket for a active gacha activity
/// @dev Use this custom error on revert function draw is out of event timestamp
error ActivityTimestampError();

/// @notice Should input valid address other than 0x0
/// @dev Use this custom error on revert function whenever validating address
error InvalidAddress();

/// @notice Should provide valid timestamp 
/// @dev Use this custom error on revert function whenever there is invalid timestamp
error InvalidTimestamp();

/// @notice Should provide valid amount of ticket 
/// @dev Use this custom error on revert function whenever there is invalid amount of ticket
error InsufficientTicket();

contract GachaDraw is Ownable {

    /// @notice Emit when a new activity is created
    /// @dev Emeits in createActivity method
    /// @param _activityId New activity Id
    /// @param _eventId Activity event Id
    /// @param _startTimestamp Activity starting timestamp
    /// @param _endTimestamp Activity end timestamp
    /// @param _rewardTokenSupply Maximumreward supply for this activity
    event ActivityCreated(
        uint256 _activityId,
        uint256 _eventId,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[5] _rewardTokenSupply
    );

    /// @notice Emit a gacha draw is completed
    /// @dev Emeits in drawTicket function
    /// @param _activityId Gacha activity Id
    /// @param _walletAddress Activity event Id
    /// @param _ticketType Used ticket type
    /// @param _ticketAmount Amount of ticket used for draw
    event DrawCompleted(
        uint256 _activityId,
        address _walletAddress,
        uint256 _ticketType,
        uint256 _ticketAmount
    );

    modifier validActivity(uint256 _activityId) {
        if (_activityId > totalActivities || _activityId < 1) {
            revert InvalidActivity();
        }
        _;
    }

    modifier validActivityType(uint256 _activitType) {
        if (
            !(_activitType == FREE_ACTIVITY_TYPE ||
                _activitType == PREMIUM_ACTIVITY_TYPE)
        ) {
            revert InvalidActivityType();
        }
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0) || _address == address(this)) {
            revert InvalidAddress();
        }
        _;
    }

    modifier validTimestamp(uint256 _startTimestamp, uint256 _endTimestamp) {
        if (_endTimestamp <= _startTimestamp) {
            revert InvalidTimestamp();
        }
        _;
    }

    uint256 public constant FREE_ACTIVITY_TYPE = 1;
    uint256 public constant PREMIUM_ACTIVITY_TYPE = 2;

    uint256 public constant MERCH_TOKEN_TYPE = 1;
    uint256 public constant GIFT_BOX_TOKEN_TYPE = 2;
    uint256 public constant AM_ITEM_TOKEN_TYPE = 3;
    uint256 public constant COMPONENT_TOKEN_TYPE = 4;
    uint256 public constant BOOSTER_TOKEN_TYPE = 5;

    uint256[5] public REWARD_TOKEN_TYPE_LIST = [
        MERCH_TOKEN_TYPE,
        GIFT_BOX_TOKEN_TYPE,
        AM_ITEM_TOKEN_TYPE,
        COMPONENT_TOKEN_TYPE,
        BOOSTER_TOKEN_TYPE
    ];

    /// @dev Ticket smart contract instance
    IAnimeMetaverseTicket public TicketContract;
    /// @dev Reward smart contract instance
    IAnimeMetaverseReward public RewardContract;

    /// @dev Activity structure for keeping track all activity information
    struct Activity {
        uint256 eventId;
        uint256 activityId;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 activityType;
        bool isActive;
        uint256[] totalRewardSupply;
        uint256[5] maximumRewardSupply;
        uint256 remainingSupply;
    }

    /// @dev Mapping to store activity information
    mapping(uint256 => Activity) public activities;

    uint256 public totalActivities = 0;
    uint256 public totalRewardWon = 0;

    /// @dev Create gacha draw contract instance
    /// @param _ticketContractAddress Ticket contract address
    /// @param _rewardContractAddress Reward contract address
    constructor(address _ticketContractAddress, address _rewardContractAddress)
    {
        TicketContract = IAnimeMetaverseTicket(_ticketContractAddress);
        RewardContract = IAnimeMetaverseReward(_rewardContractAddress);
    }

    /// @notice Owner only method for updating ticket token contract
    /// @dev Update ticket contract address
    /// @param _ticketContractAddress New ticket contract address
    function setTicketContract(address _ticketContractAddress)
        external
        onlyOwner
        validAddress(_ticketContractAddress)
    {
        TicketContract = IAnimeMetaverseTicket(_ticketContractAddress);
    }

    /// @notice Owner only method for updating reward token contract
    /// @dev Update reward contract address
    /// @param _rewardContractAddress New reward contract address
    function setRewardContract(address _rewardContractAddress)
        external
        onlyOwner
        validAddress(_rewardContractAddress)
    {
        RewardContract = IAnimeMetaverseReward(_rewardContractAddress);
    }

    /// @notice Owner only method for creating an activity for gacha draw
    /// @dev Create a new activity
    /// @param _eventId For keeping the track under which event this activity exists
    /// @param _startTimestamp Activity starting time
    /// @param _endTimestamp Activity ending time
    /// @param _activityType Activity type: free or premium
    /// @param _maxMerchTokenSupply Max supply for merch reward token
    /// @param _maxGiftBoxTokenSupply Max supply for giftbox reward token
    /// @param _maxAmItemTokenSupply Max supply for AM item reward token
    /// @param _maxComponentTokenSupply Max supply for component reward token
    /// @param _maxBoosterTokenSupply Max supply for component reward token
    function createActivity(
        uint256 _eventId,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _activityType,
        uint256 _maxMerchTokenSupply,
        uint256 _maxGiftBoxTokenSupply,
        uint256 _maxAmItemTokenSupply,
        uint256 _maxComponentTokenSupply,
        uint256 _maxBoosterTokenSupply
    )
        external
        onlyOwner
        validActivityType(_activityType)
        validTimestamp(_startTimestamp, _endTimestamp)
    {
        uint256 remainingSupply = _maxMerchTokenSupply +
            _maxGiftBoxTokenSupply +
            _maxAmItemTokenSupply +
            _maxComponentTokenSupply +
            _maxBoosterTokenSupply;

        /// @dev validate supply input
        if (remainingSupply < 1) {
            revert InsufficientReward();
        }

        uint256[5] memory maxRewardSupply = [
            _maxMerchTokenSupply,
            _maxGiftBoxTokenSupply,
            _maxAmItemTokenSupply,
            _maxComponentTokenSupply,
            _maxBoosterTokenSupply
        ];

        totalActivities++;

        /// @dev Store activity information in map
        activities[totalActivities] = Activity({
            eventId: _eventId,
            activityId: totalActivities,
            startTimestamp: _startTimestamp,
            endTimestamp: _endTimestamp,
            activityType: _activityType,
            isActive: true,
            totalRewardSupply: new uint256[](5),
            maximumRewardSupply: maxRewardSupply,
            remainingSupply: remainingSupply
        });

        /// @dev emit event after creating activity
        emit ActivityCreated(
            totalActivities,
            _eventId,
            _startTimestamp,
            _endTimestamp,
            maxRewardSupply
        );
    }

    /// @notice Owner only method for updating activity status
    /// @dev Sets activity as active or inactive
    /// @param _activityId Activity Id for which the status will be updated
    /// @param _flag Activity status flag
    function setActivityStatus(uint256 _activityId, bool _flag)
        external
        onlyOwner
        validActivity(_activityId)
    {
        activities[_activityId].isActive = _flag;
    }

    /// @notice Owner only method for updating activity timestamp
    /// @dev Update new timestamp
    /// @param _activityId Activity Id for which the timestamp will be updated
    /// @param _startTimestamp New start timestamp
    /// @param _endTimestamp New end timestamp
    function setActivityTimestamp(
        uint256 _activityId,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    )
        external
        onlyOwner
        validActivity(_activityId)
        validTimestamp(_startTimestamp, _endTimestamp)
    {
        activities[_activityId].startTimestamp = _startTimestamp;
        activities[_activityId].endTimestamp = _endTimestamp;
    }

    /// @notice External only owner function for updating giftbox reward supply.
    /// @dev Update giftbox reward type maximum suply
    /// @param _activityId Activity Id for which the reward supply will be updated
    /// @param _maxGiftBoxTokenSupply New max reward supply for giftbox reward
    function updateGiftBoxSupply(
        uint256 _activityId,
        uint256 _maxGiftBoxTokenSupply
    ) external onlyOwner validActivity(_activityId) {
        /// @notice Revert if the total reward supply already exits the new max reward supply
        /// @dev Validate the new max supply
        require(
            _maxGiftBoxTokenSupply >
                activities[_activityId].totalRewardSupply[1],
            "Giftbox supply should be greater than current total supply."
        );

        /// @dev Update remaining supply for activity
        if(_maxGiftBoxTokenSupply >= activities[_activityId].maximumRewardSupply[1]) {
            activities[_activityId].remainingSupply +=
                (_maxGiftBoxTokenSupply -
                activities[_activityId].maximumRewardSupply[1]);
        }
        else {
            activities[_activityId].remainingSupply -=
                (activities[_activityId].maximumRewardSupply[1] - 
                _maxGiftBoxTokenSupply);
        }

        ///@dev Set new max supply for
        activities[_activityId].maximumRewardSupply[1] = _maxGiftBoxTokenSupply;
    }

    /// @notice External function for gacha draw. It burns tickets and provide rewards
    /// @dev Randomly choice reward tickets, burn the gacha tickets and then mint the reward for user
    /// @param _activityId Id of the activity for which users want to draw tickets
    /// @param _ticketAmount Id of the activity for getting total reward token supply
    function drawTicket(uint256 _activityId, uint256 _ticketAmount)
        external
        validActivity(_activityId)
    {
        Activity storage activity = activities[_activityId];

        /// @notice Reverts if the activity is not active
        /// @dev Validates if the activity is active or not
        if (!activity.isActive) {
            revert InactiveActivity();
        }

        /// @notice Reverts if current timestamp is out of range of the activity start and end timestamp
        /// @dev Validates if the current timestamp is within activity start and end timestamp
        if (
            block.timestamp < activity.startTimestamp ||
            block.timestamp > activity.endTimestamp
        ) {
            revert ActivityTimestampError();
        }

        if (_ticketAmount < 1) {
            revert InsufficientTicket();
        }

        /// @notice Reverts if the rewards supply is not enough
        /// @dev Validates if there are enough tickets or not
        if (activity.remainingSupply < _ticketAmount) {
            revert InsufficientReward();
        }

        /// @dev For each tickets burns the tickets and mint a random reward
        for (uint256 i = 0; i < _ticketAmount; i++) {
            uint256 randomIndex = getRandomNumber(activity.remainingSupply);

            uint256 selectedTokenType = 0;
            uint256 indexCount = 0;

            /// @dev Find out the choosen reward time and increase it's supply
            for (uint256 j = 0; j < REWARD_TOKEN_TYPE_LIST.length; j++) {
                uint256 remaining = activities[_activityId].maximumRewardSupply[j] 
                - activities[_activityId].totalRewardSupply[j];
                indexCount += remaining;

                if (remaining > 0 && indexCount >= randomIndex) {
                    selectedTokenType = REWARD_TOKEN_TYPE_LIST[j];
                    activities[_activityId].totalRewardSupply[j]++;
                    break;
                }
            }

            ///@dev Mints one randomly choosen reward ticket
            RewardContract.mintBatch(
                _activityId,
                msg.sender,
                selectedTokenType,
                1,
                ""
            );

            activity.remainingSupply--;
            totalRewardWon++;
        }

        /// @dev Burns the tickets
        TicketContract.burn(activity.activityType, msg.sender, _ticketAmount);

        emit DrawCompleted(
            _activityId,
            msg.sender,
            activity.activityType,
            _ticketAmount
        );
    }

    /// @notice Internal function for generating random number
    /// @dev Generate a randmom number where, 0 <= randomnumber < _moduler
    /// @param _moduler The range for generating random number
    function getRandomNumber(uint256 _moduler) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        totalRewardWon
                )
            )
        );

        return (seed - ((seed / _moduler) * _moduler));
    }

    /// @notice getTotalRewardSupply is a external view method which has no gas fee
    /// @dev Provides the saved total reward token supply for any activity
    /// @param _activityId Id of the activity for getting total reward token supply
    function getTotalRewardSupply(uint256 _activityId)
        external
        view
        returns (uint256[] memory)
    {
        return activities[_activityId].totalRewardSupply;
    }

    /// @notice getMaximumRewardSupply is a external view method which has no gas fee
    /// @dev Provides the saved maximum reward token supply for any activity
    /// @param _activityId Id of the activity for getting maximum reward token supply
    function getMaximumRewardSupply(uint256 _activityId)
        external
        view
        returns (uint256[5] memory)
    {
        return activities[_activityId].maximumRewardSupply;
    }
}
