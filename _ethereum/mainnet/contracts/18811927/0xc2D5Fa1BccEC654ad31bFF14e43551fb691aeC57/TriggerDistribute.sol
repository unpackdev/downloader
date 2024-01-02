// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IFeeDistributor.sol";

contract TriggerDistribute is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    IFeeDistributor public feeDistributor;
    uint256 WEEK;
    uint256 DAY;
    mapping(uint256 => bool) public triggerWeekStatus;

    event TriggerBurnUser(
        address indexed user,
        uint256 indexed triggerWeek,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _feeDistributor) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        WEEK = 7 days;
        DAY = 1 days;
        feeDistributor = IFeeDistributor(_feeDistributor);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    modifier onlyTriggeredOnceWeek() {
        require((block.timestamp / 1 days + 4) % 7 == 1, "expired");
        require(
            !triggerWeekStatus[getMondayTimestamp(block.timestamp)],
            "only triggered once a week"
        );
        _;
    }

    function floorToWeek(uint256 t) public view returns (uint256) {
        return (t / WEEK) * WEEK;
    }

    function getNextTriggerTime() public view returns (uint256) {
        uint256 mondayTimestamp = getMondayTimestamp(block.timestamp);
        return mondayTimestamp + WEEK;
    }

    function getMondayTimestamp(
        uint256 timestamp
    ) public view returns (uint256 mondayTimestamp) {
        uint256 currentDay = (timestamp / DAY) * DAY;
        // Calculate the current day of the week (0 represents Sunday, 1 represents Monday, and so on)
        uint256 currentDayOfWeek = (timestamp / DAY + 4) % 7;
        // Calculate the seconds until Monday (assuming Monday is the start of the week)
        uint256 secondsUntilMonday = currentDayOfWeek == 0
            ? (7 - 1) * DAY
            : (currentDayOfWeek - 1) * DAY;

        // Calculate the timestamp for Monday 0:00 of the current week
        mondayTimestamp = currentDay - secondsUntilMonday;
    }

    function burn() public onlyTriggeredOnceWeek {
        feeDistributor.distribute();
        uint256 mondayTimestamp = getMondayTimestamp(block.timestamp);
        triggerWeekStatus[mondayTimestamp] = true;
        emit TriggerBurnUser(msg.sender, mondayTimestamp, block.timestamp);
    }
}
