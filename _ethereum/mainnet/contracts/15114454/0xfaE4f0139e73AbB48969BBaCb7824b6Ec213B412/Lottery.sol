// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./KeeperCompatible.sol";
import "./Ownable.sol";
import "./IERC20.sol";

error Lottery__NotEnoughToEnter();
error Lottery__PrizeSendError();
error Lottery_NotOpened();
error Lottery__UpkeepNotNeeded(
    uint256 _contractBalance,
    uint256 _playersLength,
    uint256 _lotteryState
);
error Lottery__OnlyHuman();
error Lottery__AdminCutSendProblem();
error Lottery__IncorrectNewFee();

/** @title Lottery Contract
 *  @author mpp1337
 *  @notice Some important notice
 *  @dev This lottery implements Chainlink Keepers and VRF V2
 */

contract Lottery is VRFConsumerBaseV2, KeeperCompatible, Ownable {
    /* TYPES */

    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /* STATE VARIABLES */

    uint256 private s_entranceFee;
    address payable[] private s_players;
    LotteryState private s_lotteryState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;
    address private s_recentWinner;
    uint256 private s_totalPayout;
    uint256 private s_currentRound;
    uint256 private s_adminFee;
    uint256 private s_gameStarted;


    /* LINK VRFCoordinator VARIABLES */

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGaslimit;
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    /* EVENTS */
    event GameStarted(address indexed player, uint256 indexed amount);
    event LotteryEnter(address indexed player, uint256 indexed amount);
    event RequestedLotteryWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner, uint256 indexed amount);

    /* FUNCTIONS */

    constructor(
        address _vrfCoordinator,
        uint256 _entranceFee,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGaslimit,
        uint256 _interval,
        uint256 adminFee
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        s_entranceFee = _entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGaslimit = _callbackGaslimit;
        
        s_lotteryState = LotteryState.OPEN;
        i_interval = _interval;
        s_currentRound = 1;
        
        s_adminFee = adminFee;

        s_gameStarted = 0;
        s_lastTimeStamp = 0;
    }

    function enterLottery() public payable {

        if(msg.sender != tx.origin) {
            revert Lottery__OnlyHuman();
        }

        if (msg.value < s_entranceFee) {
            revert Lottery__NotEnoughToEnter();
        }

        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery_NotOpened();
        }

        if(s_players.length == 0) {
            s_gameStarted = block.timestamp;
            
            emit GameStarted(msg.sender, msg.value);
        } 
        
        s_lastTimeStamp = block.timestamp;

        s_players.push(payable(msg.sender));

        emit LotteryEnter(msg.sender, msg.value);
    }

    /**
     * @dev This is the function that the chainlink keep nodes
     * call and they look for the `upKeeperNeeded` to return true
     * The following should be true in order to return true
     * 1. Out time interval should have passed
     * 2. The lottery should have at least 1 player, and have some eth
     * 3. Subscription is funded with LINK
     * 4. Lottery should be in an opened state
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /*performData */
        )
    {
        bool isOpened = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = ((block.timestamp - s_gameStarted) > i_interval);
        bool enoughPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        bool gameStarted = (s_gameStarted > 0);
        upkeepNeeded = (isOpened && timePassed && enoughPlayers && hasBalance && gameStarted);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }

        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGaslimit,
            NUM_WORDS
        );

        emit RequestedLotteryWinner(requestId);
    }

    function fulfillRandomWords(uint256, uint256[] memory _randomWords)
        internal
        override
    {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        uint256 balance = address(this).balance;
        uint256 adminCut = (balance / 100) * s_adminFee;
        uint256 winnerCut = balance - adminCut;
        (bool successWinner, ) = winner.call{ value: winnerCut }("");

        if (!successWinner) {
            revert Lottery__PrizeSendError();
        }

        (bool successAdmin, ) = payable(owner()).call{value: adminCut}("");

        if (!successAdmin) {
            revert Lottery__AdminCutSendProblem();
        }

        s_lotteryState = LotteryState.OPEN;
        s_recentWinner = winner;
        s_totalPayout += winnerCut;
        s_gameStarted = 0;
        s_currentRound++;

        emit WinnerPicked(winner, winnerCut);
    }

    receive() external payable {
        enterLottery();
    }

    /* ADMIN FUNCTIONS */

    function setAdminFee(uint256 newFee) external onlyOwner {
        if(newFee > 25 && (s_lotteryState == LotteryState.OPEN)) {
            revert Lottery__IncorrectNewFee();
        }
        s_adminFee = newFee;
    }

    // withdraw tokens sent to this contract (tokens are not part of this game)
    function withdrawDonatedERC20(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    // owner can change entrance fee based on current rate
    function changeEntranceFee(uint256 newEntranceFee) external onlyOwner {
        s_entranceFee = newEntranceFee;
    }

    /* VIEW / PURE FUNCTIONS */
    function getEntranceFee() external view returns (uint256) {
        return s_entranceFee;
    }

    function getPlayer(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLotteryState() external view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() external pure returns (uint32) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getGameStarted() external view returns (uint256) {
        if(s_players.length > 0) {
            return s_gameStarted;
        }

        return 0;
    }

    function getAdminFee() external view returns (uint256) {
        return s_adminFee;
    }


    function getRequestConfirmations() external pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getTotalPayout() external view returns (uint256) {
        return s_totalPayout;
    }

    function getPlayers() external view returns (address payable[] memory) {
        return s_players;
    }

    function getCurrentRound() external view returns (uint256) {
        return s_currentRound;
    }
}
