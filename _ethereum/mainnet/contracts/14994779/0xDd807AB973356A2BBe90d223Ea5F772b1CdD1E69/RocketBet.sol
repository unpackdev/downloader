pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


contract RocketBet is VRFConsumerBaseV2, Ownable {
    using SafeMath for uint256;
    VRFCoordinatorV2Interface COORDINATOR;

    //VRF values
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash = 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    mapping(uint256 => address) public requestIdToSender;

    //player info
    struct Player{
        uint256 bets;
        uint256 losses;
        uint256 tokensSpent;
        uint256 tokensWon;
    }

    mapping(address => Player) public playerInfo;

    struct Bet {
        uint256 choice;
        uint256 wager;
    }

    mapping(address => Bet) public playerBetInfo;

    //game info
    uint256 public tokensWon = 0;
    uint256 public tokensLost = 0;
    uint256 public totalCoinFlips = 0;
    uint256 public coinFlipsLost = 0;

    bool disabledGame = false;
 

    //Rocket Token
    IERC20 rocketToken;
    address devWallet;

    //events

    event BetPlaced(
       uint256 betAmount,
       address bettor,
       uint256 choice
    );

    event playerWon(
        uint256 betAmount,
        uint256 amountWon,
        address bettor,
        uint256 choice,
        uint256 winningChoice,
        uint256 randRequestId,
        uint256 randomness
    );

    event playerLost (
        uint256 betAmount,
        address bettor,
        uint256 choice,
        uint256 winningChoice,
        uint256 randRequestId,
        uint256 randomness
    );

    event GameClosed (
        bool gameEnabled
    );

        event GameOpen (
        bool gameEnabled
    );

    constructor(uint64 subscriptionId, address _rocketToken) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
    rocketToken = IERC20(_rocketToken);
  }

  function shutDownGame() public onlyOwner {
      disabledGame = true;
      uint256 amountInContract = rocketToken.balanceOf(address(this));
      rocketToken.transfer(msg.sender, amountInContract);
      emit GameClosed(false);
  }

  function enableGame() public onlyOwner {
      disabledGame = false;
      emit GameOpen(true);
  }

  function placeBet(uint256 wager, uint16 bet) public payable {
      require(!disabledGame, "game is shut down");
      require(wager > 0, "must place a non 0 bet");
      uint256 allowance = rocketToken.allowance(msg.sender, address(this));
      require(allowance >= wager, "Check token allowance");
      uint256 maxbet = rocketToken.balanceOf(address(this)).div(4);
      require(wager <= maxbet, "cannot place wager over max bet");
      require(bet < 2, "bet must be 0 or 1");

      //transfer wager to contract
      rocketToken.transferFrom(msg.sender, address(this), wager);

      //set bet info
      Bet memory _bet;
      _bet.wager = wager;
      _bet.choice = bet;

      playerBetInfo[msg.sender] = _bet;

      playerInfo[msg.sender].bets += 1;
      playerInfo[msg.sender].tokensSpent += wager;

      totalCoinFlips += 1;

      requestRandomWords(msg.sender);
      emit BetPlaced(wager, msg.sender, bet);
  }

      //gets random number
    function requestRandomWords(address _sender) private {
    // Will revert if subscription is not set and funded.
    uint256 s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    requestIdToSender[s_requestId] = _sender;
  }
  
  function fulfillRandomWords(
    uint256 s_requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
      //pick winner
      uint256 winningBet = randomWords[0] % 2;
      address _bettor = requestIdToSender[s_requestId];
      Bet memory _bet = playerBetInfo[_bettor];
      Bet memory _blankBet;

      //reset values
      playerBetInfo[_bettor] = _blankBet;
      
      if(_bet.choice == winningBet){
          uint256 winnings = _bet.wager.mul(2);
          uint256 fee = winnings.mul(10).div(100);
          winnings -= fee;

          playerInfo[_bettor].tokensWon += winnings;
          tokensWon += winnings;

          rocketToken.transfer(_bettor, winnings);
          emit playerWon(_bet.wager, winnings, _bettor, _bet.choice, winningBet, s_requestId, randomWords[0]);
      }
      else {
          
          playerInfo[_bettor].losses += 1;
          coinFlipsLost += 1;
          tokensLost += _bet.wager;

          emit playerLost(_bet.wager, _bettor, _bet.choice, winningBet, s_requestId, randomWords[0]);
      }

    }
}