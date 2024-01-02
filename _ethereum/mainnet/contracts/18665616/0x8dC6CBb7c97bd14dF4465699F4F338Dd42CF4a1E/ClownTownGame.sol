/**
                                                                       ,----,
                                                                     ,/   .`|
  ,----..    ,--,                                                  ,`   .'  :
 /   /   \ ,--.'|                                                ;    ;     /
|   :     :|  | :     ,---.           .---.      ,---,         .'___,/    ,'  ,---.           .---.      ,---,
.   |  ;. /:  : '    '   ,'\         /. ./|  ,-+-. /  |        |    :     |  '   ,'\         /. ./|  ,-+-. /  |
.   ; /--` |  ' |   /   /   |     .-'-. ' | ,--.'|'   |        ;    |.';  ; /   /   |     .-'-. ' | ,--.'|'   |
;   | ;    '  | |  .   ; ,. :    /___/ \: ||   |  ,"' |        `----'  |  |.   ; ,. :    /___/ \: ||   |  ,"' |
|   : |    |  | :  '   | |: : .-'.. '   ' .|   | /  | |            '   :  ;'   | |: : .-'.. '   ' .|   | /  | |
.   | '___ '  : |__'   | .; :/___/ \:     '|   | |  | |            |   |  ''   | .; :/___/ \:     '|   | |  | |
'   ; : .'||  | '.'|   :    |.   \  ' .\   |   | |  |/             '   :  ||   :    |.   \  ' .\   |   | |  |/
'   | '/  :;  :    ;\   \  /  \   \   ' \ ||   | |--'              ;   |.'  \   \  /  \   \   ' \ ||   | |--'
|   :    / |  ,   /  `----'    \   \  |--" |   |/                  '---'     `----'    \   \  |--" |   |/
 \   \ .'   ---`-'              \   \ |    '---'                                        \   \ |    '---'
  `---`                          '---"                                                   '---"

Its 🤡 clown's 🤡
.
all the
.
.
way
.
.
.
down
.
.
.
.
**/

// SPDX-License-Identifier: CLOWNWARE
pragma solidity 0.8.19;

import "./IClownTownStaking.sol";
import "./Ownable.sol";

contract ClownTownGame is Ownable {
  event CreateRound(address indexed user, uint256 roundIndex);
  event Wager(address indexed user, uint256 indexed roundIndex, bool sideA, uint256 amount);
  event ClaimWinnings(address indexed user, uint256 indexed roundIndex, uint256 amount);
  event ClaimCreatorFees(address indexed user, uint256 indexed roundIndex, uint256 amount);

  // Pack into single storage slot
  uint64 public numRounds;
  uint32 public roundDuration;
  uint16 public maxRoundDescription;
  uint16 public betFeeBpsTotal;
  uint16 public betFeeBpsToCreator;
  uint16 public betFeeBpsToStakers;

  uint256 public maxBet;
  uint256 public minBet;

  int256 public clownVersion = 12345;

  IClownTownStaking public stakingContract;
  address payable public feeWallet;
  RoundInfo[] public rounds;

  mapping(address => mapping(uint256 => bool)) _userRounds;
  mapping(address => uint256[]) public userRounds;

  bool betaPeriod;

  struct RoundInfo {
    address creator;
    string description;

    string sideAHandle;
    string sideBHandle;

    uint256 startBlock;
    uint256 endBlock;

    uint256 totalSideA;
    uint256 totalSideB;

    mapping(address => uint256) sideABets;
    mapping(address => uint256) sideBBets;
    mapping(address => bool) winningsClaimed;

    uint256 unclaimedCreatorFees;
  }

  constructor(
    IClownTownStaking _stakingContract,
    address payable _feeWallet,
    uint256 _minBet,
    uint256 _maxBet,
    uint32 _roundDuration,
    uint16 _maxRoundDescription,
    uint16 _betFeeBpsTotal,
    uint16 _betFeeBpsToCreator,
    uint16 _betFeeBpsToStakers) {
    require(address(_stakingContract)!=address(0));
    require(_feeWallet!=address(0));

    stakingContract = _stakingContract;
    feeWallet = _feeWallet;
    setRoundParams(_minBet, _maxBet, _roundDuration, _maxRoundDescription);
    setBetFees(_betFeeBpsTotal, _betFeeBpsToCreator, _betFeeBpsToStakers);
    betaPeriod = true;
  }

  function setStakingContract(IClownTownStaking _stakingContract) public onlyOwner {
    require(address(_stakingContract)!=address(0));
    stakingContract = _stakingContract;
  }

  function setFeeWallet(address payable _feeWallet) public onlyOwner {
    require(_feeWallet!=address(0));
    feeWallet = _feeWallet;
  }

  function setRoundParams(
    uint256 _minBet,
    uint256 _maxBet,
    uint32 _roundDuration,
    uint16 _maxRoundDescription) public onlyOwner {
    require(_minBet > 0);
    require(_maxBet >= _minBet);
    require(_roundDuration > 0);
    minBet = _minBet;
    maxBet = _maxBet;
    roundDuration = _roundDuration;
    maxRoundDescription = _maxRoundDescription;
  }

  function setBetFees(
    uint16 _betFeeBpsTotal,
    uint16 _betFeeBpsToCreator,
    uint16 _betFeeBpsToStakers) public onlyOwner {
    require(_betFeeBpsTotal < 10000);
    require(_betFeeBpsToCreator+_betFeeBpsToStakers <= _betFeeBpsTotal);
    betFeeBpsTotal = _betFeeBpsTotal;
    betFeeBpsToCreator = _betFeeBpsToCreator;
    betFeeBpsToStakers = _betFeeBpsToStakers;
  }

  // Irreversible
  function endBetaPeriod() public onlyOwner {
    betaPeriod = false;
  }

  // In case of contract bug. Permanently disabled after beta period
  function emergencyWithdraw(
    address payable target,
    uint256 amount) public onlyOwner {
    require(betaPeriod);
    target.transfer(amount);
  }

  function createRound(
    string calldata _description,
    string calldata _sideAHandle,
    string calldata _sideBHandle) public {
    require(bytes(_description).length <= maxRoundDescription);
    require(bytes(_sideAHandle).length <= 50);
    require(bytes(_sideBHandle).length <= 50);

    rounds.push();
    numRounds++;

    uint256 roundIndex = numRounds-1;
    RoundInfo storage round = rounds[roundIndex];
    round.creator = msg.sender;
    round.description = _description;
    round.sideAHandle = _sideAHandle;
    round.sideBHandle = _sideBHandle;
    round.startBlock = block.number;
    round.endBlock = block.number + roundDuration;

    if (!_userRounds[msg.sender][roundIndex]) {
      _userRounds[msg.sender][roundIndex] = true;
      userRounds[msg.sender].push(roundIndex);
    }

    emit CreateRound(msg.sender, roundIndex);
  }

  function wager(
    uint32 roundIndex,
    bool sideA) public payable {
    uint256 amount = msg.value;
    require(amount >= minBet, "wager: amount too small");
    require(amount <= maxBet, "wager: amount too big");
    require(roundIndex < rounds.length, "wager: invalid round");

    RoundInfo storage round = rounds[roundIndex];
    require(block.number <= round.endBlock, "wager: round over");

    uint256 feeTotal = (amount * betFeeBpsTotal) / 10000;
    uint256 feeToCreator = (amount * betFeeBpsToCreator) / 10000;
    uint256 feeToStakers = (amount * betFeeBpsToStakers) / 10000;
    require((feeToCreator+feeToStakers)<=feeTotal); // Sanity check

    uint256 amountAfterFee = amount - feeTotal;

    if (sideA) {
      round.totalSideA += amountAfterFee;
      round.sideABets[msg.sender] += amountAfterFee;
    }
    else {
      round.totalSideB += amountAfterFee;
      round.sideBBets[msg.sender] += amountAfterFee;
    }

    round.unclaimedCreatorFees += feeToCreator;
    stakingContract.addEthReward{value: feeToStakers}();
    feeWallet.transfer(feeTotal-feeToCreator-feeToStakers);

    if (!_userRounds[msg.sender][roundIndex]) {
      _userRounds[msg.sender][roundIndex] = true;
      userRounds[msg.sender].push(roundIndex);
    }

    emit Wager(msg.sender, roundIndex, sideA, amount);
  }

  function claimWinnings(uint256 roundIndex) public {
    RoundInfo storage round = rounds[roundIndex];
    require(round.endBlock < block.number);
    require(!round.winningsClaimed[msg.sender]);

    round.winningsClaimed[msg.sender] = true;
    uint256 winnings = currentWinnings(msg.sender, roundIndex);

    if (winnings > 0) {
      payable(msg.sender).transfer(winnings);
      emit ClaimWinnings(msg.sender, roundIndex, winnings);
    }
  }

  function currentWinnings(address user, uint256 roundIndex) public view returns (uint256) {
    RoundInfo storage round = rounds[roundIndex];
    if (round.totalSideA > round.totalSideB) {
      uint256 userBet = round.sideABets[user];
      return userBet + (userBet * round.totalSideB / round.totalSideA);
    }
    else if (round.totalSideB > round.totalSideA) {
      uint256 userBet = round.sideBBets[user];
      return userBet + (userBet * round.totalSideA / round.totalSideB);
    }
    else {
      return round.sideABets[user] + round.sideBBets[user];
    }
  }

  function claimCreatorFees(uint256 roundIndex) public {
    RoundInfo storage round = rounds[roundIndex];
    require(round.creator==msg.sender);
    require(round.endBlock < block.number);

    if (round.unclaimedCreatorFees > 0) {
      payable(msg.sender).transfer(round.unclaimedCreatorFees);
      emit ClaimCreatorFees(msg.sender, roundIndex, round.unclaimedCreatorFees);
      round.unclaimedCreatorFees = 0;
    }
  }

  function numUserRounds(address user) public view returns (uint256) {
    return userRounds[user].length;
  }

  function winningsClaimed(address user, uint256 roundIndex) public view returns (bool) {
    return rounds[roundIndex].winningsClaimed[user];
  }
}