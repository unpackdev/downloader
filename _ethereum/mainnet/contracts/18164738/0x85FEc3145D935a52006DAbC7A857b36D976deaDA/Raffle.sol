// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./AutomationCompatibleInterface.sol";
import "./console.sol";
import "./IERC20.sol";
import "./Ownable.sol";

/* Errors */
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Raffle__RaffleNotOpen();

/**@title Burger Raffle Contract
 * @author Credits to Patrick Collins for inspiration and secure boilerplate
 * @notice This contract is lottery for flrbrg.io
 * @dev This implements the Chainlink VRF Version 2 and Chainlink Upkeepers
 */
contract Raffle is Ownable, VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* Burger declaration */
    IERC20 public immutable i_FLRBRG;

    mapping(uint256 => mapping(address => uint256)) private s_tickets;
    mapping(uint256 => address) private s_playersMapping;

    /* State variables */
    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    uint256 private s_interval;
    uint256 private s_entranceFee;
    uint256 private s_lastTimeStamp;
    uint256 private s_seventhDayTimeStamp;
    address private s_recentWinner;
    address private s_V1;
    address private s_V2;
    address private s_burn;
    RaffleState private s_raffleState;
    uint256 private s_treasuryV1Balance;
    uint256 private s_treasuryV2Balance;
    uint256 private s_raffleBalance;
    uint256 private s_raffleBalanceSeventhDay;
    uint256 private s_burnBalance;
    uint256 private s_feePercentV1;
    uint256 private s_feePercentV2;
    uint256 private s_feePercentRaffleSeventhDay;
    uint256 private s_feePercentBurn;
    uint256 private s_gameCount = 1;
    uint256 private s_lotteryDay = 1;
    uint256 private s_playersCount;

    /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player, uint256 indexed ticketsOfPlayer, uint256 gameCount);
    event WinnerPicked(
        address indexed player,
        uint256 indexed ticketsOfPlayer,
        uint256 indexed amountWon,
        uint256 gameCount,
        uint256 ticketsInRound
    );
    event WeeklyWinnerPicked(
        address indexed player,
        uint256 indexed ticketsOfPlayer,
        uint256 indexed amountWon,
        uint256 gameCount,
        uint256 ticketsInRound
    );

    /* Functions */
    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit,
        address FLRBRG,
        address V1,
        address V2
    ) Ownable() VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        s_interval = interval;
        i_subscriptionId = subscriptionId;
        s_entranceFee = entranceFee;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
        i_FLRBRG = IERC20(FLRBRG);
        s_V1 = V1;
        s_V2 = V2;
    }

    function enterRaffle(uint256 entries) public {
        require(
            i_FLRBRG.allowance(msg.sender, address(this)) >= (s_entranceFee * entries),
            "registration cost no met"
        );
        require(
            (i_FLRBRG.transferFrom(msg.sender, address(this), (s_entranceFee * entries))) &&
                entries > 0
        );

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_raffleBalanceSeventhDay += (((s_entranceFee * entries) *
            (s_feePercentRaffleSeventhDay * 1e2)) / 1e4);
        s_treasuryV1Balance += (((s_entranceFee * entries) * (s_feePercentV1 * 1e2)) / 1e4);
        s_treasuryV2Balance += (((s_entranceFee * entries) * (s_feePercentV2 * 1e2)) / 1e4);
        s_burnBalance += (((s_entranceFee * entries) * (s_feePercentBurn * 1e2)) / 1e4);
        s_raffleBalance += ((s_entranceFee * entries) -
            (((s_entranceFee * entries) * (s_feePercentRaffleSeventhDay * 1e2)) / 1e4) -
            (((s_entranceFee * entries) * (s_feePercentV1 * 1e2)) / 1e4) -
            (((s_entranceFee * entries) * (s_feePercentV2 * 1e2)) / 1e4) -
            (((s_entranceFee * entries) * (s_feePercentBurn * 1e2)) / 1e4));
        for (uint256 i = 0; i < entries; i++) {
            s_playersMapping[s_playersCount] = msg.sender;
            ++s_playersCount;
            ++s_tickets[s_gameCount][msg.sender];
        }
        emit RaffleEnter(msg.sender, s_tickets[s_gameCount][msg.sender], s_gameCount);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > s_interval);
        bool hasPlayers = s_playersCount > 0;
        bool hasBalance = s_raffleBalance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(s_raffleBalance, s_playersCount, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        if (s_lotteryDay == 7) {
            uint256 indexOfWinner = randomWords[0] % s_playersCount;
            address recentWinner = s_playersMapping[indexOfWinner];
            s_recentWinner = recentWinner;
            s_raffleState = RaffleState.OPEN;
            s_lastTimeStamp = block.timestamp;
            s_seventhDayTimeStamp = block.timestamp;
            uint256 playersCount = s_playersCount;
            s_playersCount = 0;
            uint256 newBalance = s_raffleBalanceSeventhDay + s_raffleBalance;
            s_raffleBalanceSeventhDay = 0;
            s_raffleBalance = 0;
            require(i_FLRBRG.transfer(s_recentWinner, newBalance), "Raffle__TransferFailed");
            s_lotteryDay = 1;
            emit WeeklyWinnerPicked(
                recentWinner,
                s_tickets[s_gameCount][s_recentWinner],
                newBalance,
                s_gameCount,
                playersCount
            );
            ++s_gameCount;
        } else {
            uint256 indexOfWinner = randomWords[0] % s_playersCount;
            address recentWinner = s_playersMapping[indexOfWinner];
            s_recentWinner = recentWinner;
            s_raffleState = RaffleState.OPEN;
            s_lastTimeStamp = block.timestamp;
            uint256 playersCount = s_playersCount;
            s_playersCount = 0;
            uint256 newBalance = s_raffleBalance;
            s_raffleBalance = 0;
            require(i_FLRBRG.transfer(s_recentWinner, newBalance), "Raffle__TransferFailed");
            ++s_lotteryDay;
            emit WinnerPicked(
                recentWinner,
                s_tickets[s_gameCount][recentWinner],
                newBalance,
                s_gameCount,
                playersCount
            );
            ++s_gameCount;
        }
    }

    /** Recovery Functions and Setters */
    function recoverTreasuryV1() external {
        require(msg.sender == s_V1, "Address Not Allowed");
        uint256 newBalance = s_treasuryV1Balance;
        s_treasuryV1Balance = 0;
        i_FLRBRG.transfer(msg.sender, newBalance);
    }

    function burnTokens() external onlyOwner {
        uint256 newBurn = s_burnBalance;
        s_burnBalance = 0;
        i_FLRBRG.transfer(0x000000000000000000000000000000000000dEaD, newBurn);
    }

    function setInterval(uint256 interval) external onlyOwner {
        s_interval = interval;
    }

    function setEntraceFee(uint256 entranceFee) external onlyOwner {
        s_entranceFee = entranceFee;
    }

    function setFeePercentV1(uint256 feePercent) external onlyOwner {
        require(feePercent <= 25, "More than 25");
        s_feePercentV1 = feePercent;
    }

    function setFeePercentV2(uint256 feePercent) external {
        require(feePercent <= 25, "More than 25");
        require(msg.sender == s_V2, "Address Not Allowed");
        s_feePercentV2 = feePercent;
    }

    function setFeePercentBurn(uint256 feePercent) external onlyOwner {
        require(feePercent <= 10, "More than 10");
        s_feePercentBurn = feePercent;
    }

    function setFeePercentRaffleSeventhDay(uint256 feePercent) external onlyOwner {
        require(feePercent <= 25, "More than 25");
        s_feePercentRaffleSeventhDay = feePercent;
    }

    function setDay(uint256 day) external onlyOwner {
        s_lotteryDay = day; //days 1-7, in case of missed day add 1 for each one
    }

    function setNewWeeklyPrize(uint256 prize) external onlyOwner {
        s_raffleBalanceSeventhDay += prize; //1e18 for prize
    }

    function recoverTreasuryV2() external {
        require(msg.sender == s_V2, "Address Not Allowed");
        uint256 newBalance = s_treasuryV2Balance;
        s_treasuryV2Balance = 0;
        i_FLRBRG.transfer(msg.sender, newBalance);
    }

    function emergencyRecovery() external onlyOwner {
        require(s_raffleState == RaffleState.CALCULATING, "Not emergency");
        uint256 newBalance = s_treasuryV2Balance;
        s_treasuryV2Balance = 0;
        i_FLRBRG.transfer(s_V2, newBalance);
        newBalance = s_treasuryV1Balance;
        s_treasuryV1Balance = 0;
        i_FLRBRG.transfer(s_V1, newBalance);
        newBalance = i_FLRBRG.balanceOf(address(this));
        s_raffleBalance = 0;
        s_raffleBalanceSeventhDay = 0;
        s_burnBalance = 0;
        i_FLRBRG.transfer(msg.sender, newBalance);
    }

    /** Getter Functions */

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_playersMapping[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return s_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return s_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_playersCount;
    }

    function getTicketsOfPlayer(address player) external view returns (uint256) {
        return s_tickets[s_gameCount][player];
    }

    function getVrfCoordinatorV2Address() public view returns (address) {
        return address(i_vrfCoordinator);
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getSeventhDayTimestamp() public view returns (uint256) {
        return s_seventhDayTimeStamp;
    }

    function getV1() public view returns (address) {
        return s_V1;
    }

    function getV2() public view returns (address) {
        return s_V2;
    }

    function getTreasuryV1Balance() public view returns (uint256) {
        return s_treasuryV1Balance;
    }

    function getTreasuryV2Balance() public view returns (uint256) {
        return s_treasuryV2Balance;
    }

    function getRaffleBalance() public view returns (uint256) {
        return s_raffleBalance;
    }

    function getRaffleBalanceSeventhDay() public view returns (uint256) {
        return s_raffleBalanceSeventhDay;
    }

    function getFeePercentV1() public view returns (uint256) {
        return s_feePercentV1;
    }

    function getBurnFeePercent() public view returns (uint256) {
        return s_feePercentBurn;
    }

    function getFeePercentRaffleSeventhDay() public view returns (uint256) {
        return s_feePercentRaffleSeventhDay;
    }

    function getGameCount() public view returns (uint256) {
        return s_gameCount;
    }

    function getCurrentLotteryDay() public view returns (uint256) {
        return s_lotteryDay;
    }

    function getBurnBalance() public view returns (uint256) {
        return s_burnBalance;
    }
}
