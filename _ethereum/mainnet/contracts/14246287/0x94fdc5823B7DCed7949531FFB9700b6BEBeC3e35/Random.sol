// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
*
        :'#######:::'#######:::'#######:::'#######:::'#######:::'#######::
        '##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:
        ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##:
        : #######::: #######::: #######::: #######::: #######::: #######::
        '##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:'##.... ##:
        ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##: ##:::: ##:
        . #######::. #######::. #######::. #######::. #######::. #######::
        :.......::::.......::::.......::::.......::::.......::::.......:::  

                              A game of chance
*/
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./SafeERC20.sol";
import "./ERC20.sol";

contract Random is VRFConsumerBaseV2 {

  using SafeERC20 for ERC20;

  VRFCoordinatorV2Interface public COORDINATOR;
  LinkTokenInterface public LINKTOKEN;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // USDT address
  ERC20 public usdt;

  // Duration that game lasts
  uint public gameDuration;

  // Time when game starts - after bootstrap
  uint public startTime;

  // Cost per dice roll
  uint public ticketSize = 1 * 10 ** 6;

  // Percentage precision
  uint public percentagePrecision = 10 ** 2;

  // Fees earmarked for VRF requests
  uint public linkFeePercent = 20 * percentagePrecision;

  // Fees for the house
  uint public houseFeePercent = 5 * percentagePrecision; // 5%

  // Fee % (10**2 precision)
  uint public feePercentage = linkFeePercent + houseFeePercent; // 25%

  // Revenue split % (10**2 precision) - all depositors with a roll above 600k get a revenue split 
  uint public revenueSplitPercentage = 20 * percentagePrecision; // 20%

  // Threshold roll above which rollers get revenue split
  uint public revenueSplitRollThreshold = 60 * 10 ** 4; // 600k

  // Total revenue collected from all dice rolls
  uint public revenue;

  // Total revenue split shares for rolls above revenue split threshold
  uint public totalRevenueSplitShares;

  // Maps users to amount earned via revenue splits shares
  mapping(address => uint) public revenueSplitSharesPerUser;

  // Tracks revenue split collected per user
  mapping (address => uint) public revenueSplitCollectedPerUser;

  // Total fees collected from all dice rolls
  uint public feesCollected;

  // Winnings distributed at bootstrap
  uint public bootstrapWinnings;

  // Toggled to true to begin the game
  bool public isBootstrapped;

  // Roll with number closest to winning number
  DiceRoll public currentWinner;

  // Winning roll
  DiceRoll public winner;

  // Number to win
  uint public winningNumber = 888888;

  // Maps request IDs to addresses that rolled dice
  mapping (uint => address) public rollRequests;

  // Tracks number of rolls - used as auto-incrementing roll ID
  uint public rollCount;

  // Store dice rolls by roll ID here
  mapping (uint => DiceRoll) public diceRolls;

  address public vrfCoordinator;

  address public link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  // 200 gwei
  bytes32 public keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
  
  uint32 public callbackGasLimit = 600000;

  // The default is 3, but you can set this higher.
  uint16 public requestConfirmations = 3;

  // Contract owner
  address owner;

  struct DiceRoll {
    // Random number on roll
    uint roll;
    // Address of roller
    address roller;
  }

  event LogNewRollRequest(uint requestId, address indexed roller);
  event LogOnRollResult(uint requestId, uint rollId, uint roll, address indexed roller);
  event LogNewCurrentWinner(uint requestId, uint rollId, uint roll, address indexed roller);
  event LogGameOver(address indexed winner, uint winnings); 
  event LogOnCollectRevenueSplit(address indexed user, uint split);

  constructor(
    uint64 subscriptionId,
    address _usdt,
    address _vrfCoordinator,
    uint _gameDuration
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);
    owner = msg.sender;
    s_subscriptionId = subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    usdt = ERC20(_usdt);
    gameDuration = _gameDuration;
  }

  // Set a new coordinator address
  function setCoordinator(address _coordinator) 
  public
  onlyOwner 
  returns (bool) {
    require(!isBootstrapped, "Contract is already bootstrapped");
    vrfCoordinator = _coordinator;
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    return true;
  }

  // Called initially to bootstrap the game
  function bootstrap(
    uint _bootstrapWinnings
  )
  public
  onlyOwner
  returns (bool) {
    require(!isBootstrapped, "Game already bootstrapped");
    bootstrapWinnings = _bootstrapWinnings;
    revenue += _bootstrapWinnings;
    isBootstrapped = true;
    startTime = block.timestamp;
    usdt.safeTransferFrom(msg.sender, address(this), _bootstrapWinnings);
    return true;
  }

  // Allows owner to collect fees
  function collectFees() 
  public
  returns (bool) {
    uint fees = getFees();
    feesCollected += fees;
    usdt.safeTransfer(owner, fees);
    return true;
  }

  // Process random words from chainlink VRF2
  function fulfillRandomWords(
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    for (uint i = 0; i < randomWords.length; i++) {
      diceRolls[++rollCount].roll = getFormattedNumber(randomWords[i]);
      diceRolls[rollCount].roller = rollRequests[requestId];

      // If the game was over between rolls - don't perform any of the below logic
      if (!isGameOver()) {
        if (diceRolls[rollCount].roll == winningNumber) {
          // User wins
          winner = diceRolls[rollCount];
          // Transfer revenue to winner
          collectFees();
          uint revenueSplit = getRevenueSplit();
          uint winnings = revenue - feesCollected - revenueSplit;
          usdt.safeTransfer(winner.roller, winnings);
          emit LogGameOver(winner.roller, winnings);
        } else if (diceRolls[rollCount].roll >= revenueSplitRollThreshold) {
          totalRevenueSplitShares += 1;
          revenueSplitSharesPerUser[diceRolls[rollCount].roller] += 1;
        }

        if (diceRolls[rollCount].roll != winningNumber) {
          int diff = getDiff(diceRolls[rollCount].roll, winningNumber);
          int currentWinnerDiff = getDiff(currentWinner.roll, winningNumber);

          if (diff <= currentWinnerDiff) 
            currentWinner = diceRolls[rollCount];

          emit LogNewCurrentWinner(requestId, rollCount, diceRolls[rollCount].roll, diceRolls[rollCount].roller);
        }
      }

      emit LogOnRollResult(requestId, rollCount, diceRolls[rollCount].roll, diceRolls[rollCount].roller);
    }
  }

  // Returns difference between 2 dice rolls
  function getDiff(uint a, uint b) private pure returns (int) {
    unchecked {
      int x = int(a-b);
      return x >= 0 ? x : -x;
    }
  }

  // Ends a game that is past it's duration without a winner
  function endGame()
  public
  returns (bool) {
    require(
      hasGameDurationElapsed() && winner.roller == address(0), 
      "Game duration hasn't elapsed without a winner"
    );
    winner = currentWinner;
    // Transfer revenue to winner
    collectFees();
    uint revenueSplit = getRevenueSplit();
    uint winnings = revenue - feesCollected - revenueSplit;
    usdt.safeTransfer(winner.roller, winnings);
    emit LogGameOver(winner.roller, winnings);
    return true;
  }

  // Allows users to collect their share of revenue split after a game is over  
  function collectRevenueSplit() external {
    require(isGameOver(), "Game isn't over");
    require(revenueSplitSharesPerUser[msg.sender] > 0, "User does not have any revenue split shares");
    require(revenueSplitCollectedPerUser[msg.sender] == 0, "User has already collected revenue split");
    uint revenueSplit = getRevenueSplit();
    uint userRevenueSplit = revenueSplit * revenueSplitSharesPerUser[msg.sender] / totalRevenueSplitShares; 
    revenueSplitCollectedPerUser[msg.sender] = userRevenueSplit;
    usdt.safeTransfer(msg.sender, userRevenueSplit);
    emit LogOnCollectRevenueSplit(msg.sender, userRevenueSplit);
  }

  // Assumes the subscription is funded sufficiently.
  function rollDice() external {
    require(isBootstrapped, "Game is not bootstrapped");
    require(!isGameOver(), "Game is over");
    revenue += ticketSize;
    usdt.safeTransferFrom(msg.sender, address(this), ticketSize);
    
    // Will revert if subscription is not set and funded.
    uint requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      1
    );
    rollRequests[requestId] = msg.sender;

    emit LogNewRollRequest(requestId, msg.sender);
  }

  // Approve USD once and roll multiple times
  function rollMultipleDice(uint32 times) external {
    require(isBootstrapped, "Game is not bootstrapped");
    require(!isGameOver(), "Game is over");
    require(times > 1 && times <= 5, "Should be >=1 and <=5 rolls in 1 txn");
    uint total = ticketSize * times;
    revenue += total;
    usdt.safeTransferFrom(msg.sender, address(this), total);
    
    // Will revert if subscription is not set and funded.
    uint requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      times
    );
    rollRequests[requestId] = msg.sender;
    emit LogNewRollRequest(requestId, msg.sender);
  }

  // Returns current available fees
  function getFees()
  public
  view
  returns (uint) {
    return ((revenue * feePercentage) / (100 * percentagePrecision)) - feesCollected;
  }

  // Returns revenue split for rollers above 600k
  function getRevenueSplit()
  public
  view
  returns (uint) {
    return ((revenue * revenueSplitPercentage) / (100 * percentagePrecision));
  }

  // Format number to 0 - 10 ** 6 range
  function getFormattedNumber(
    uint number
  )
  public
  pure
  returns (uint) {
    return number % 1000000 + 1;
  }

  // Returns whether the game is still running
  function isGameOver()
  public
  view
  returns (bool) {
    return winner.roller != address(0) || hasGameDurationElapsed();
  }

  // Returns whether the game duration has ended
  function hasGameDurationElapsed()
  public
  view
  returns (bool) {
    return block.timestamp > startTime + gameDuration;
  }

  function updateCallbackGasLimit(uint32 limit)
  public
  onlyOwner returns (bool) {
    require(limit >= 500000, "Limit must be >=500000");
    callbackGasLimit = limit;
    return true;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}
