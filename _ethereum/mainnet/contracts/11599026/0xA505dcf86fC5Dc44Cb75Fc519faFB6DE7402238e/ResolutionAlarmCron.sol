// SPDX-License-Identifier: MPL-2.0

pragma solidity >=0.6.0;

import "./GovernanceInterface.sol";
import "./LotteryInterface.sol";

/** 
 * @title Helper contract to restart lotteries after fixed periods of time using external cronjob.
 * @dev Resolve lottery results periodically.
 */
contract ResolutionAlarmCron {
    GovernanceInterface public immutable TrustedGovernance;
    LotteryInterface public TrustedLottery;

    mapping(address => bool) public alarmNodes;

    modifier onlyAlarmNodes() {
        require(alarmNodes[msg.sender], "Only alarm nodes");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == TrustedGovernance.owner(), "Only owner");
        _;
    }

    /** 
     * @dev L7L DAO should be in charge of Alarm contract.
     *
     * @param _governance Governance contract address.
     */
    constructor(address _governance) public {
        TrustedGovernance = GovernanceInterface(_governance);
    }

    /**
     * @dev Set lottery contract controlled by this alarm,
     * unprotected because called once.
     *
     * @param _lottery Lottery contract to be alarmed.
     */
    function initialize(address _lottery) external {
        require(address(TrustedLottery) == address(0), "Lottery is immutable");

        TrustedLottery = LotteryInterface(_lottery);
    }

    /**
     * @dev Lottery should fulfill in lotteryPeriod minutes, 
     * not used in cron resolvers, preserved for interface consistency.
     * 
     * Lottery period is defined on alarm node side.
     *
     * @param _period Minutes until lottery resolution.
     */
    function setAlarm(uint32 _period) external {}

    /** 
     * @dev Checks if game is ready for resolution.
     */
    function canResolve() public view returns (bool) {
        TrustedLottery.canResolve();
    }

    /** 
     * @dev Call resolution lottery function when alarm notification comes from Chainlink.
     */
    function fulfillAlarm() external onlyAlarmNodes {
        TrustedLottery.results();
    }

    /** 
     * @dev Checks if game is ready to continue after resolution.
     */
    function canContinue() public view returns (bool) {
        TrustedLottery.canContinue();
    }

    /** 
     * @dev Call resolution lottery function when alarm notification comes from Chainlink.
     */
    function continueGame() external onlyAlarmNodes {
        TrustedLottery.continueGame();
    }

    /** 
     * @dev Register alarm node.
     *
     * @param _alarmNode Enable alarm node.
     */
    function enableAlarmNode(address _alarmNode) external onlyDAO {
        alarmNodes[_alarmNode] = true;
    }

    /** 
     * @dev Unregister alarm node.
     *
     * @param _alarmNode Disable alarm node.
     */
    function disableAlarmNode(address _alarmNode) external onlyDAO {
        alarmNodes[_alarmNode] = false;
    }
}
