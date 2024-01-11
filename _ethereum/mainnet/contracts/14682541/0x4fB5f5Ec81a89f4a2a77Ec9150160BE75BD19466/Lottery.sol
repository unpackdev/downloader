// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/**
 * @title Lottery
 * @dev Chainlink VRF powered lottery for ERC-20 tokens
 */
contract Lottery is Ownable, VRFConsumerBaseV2 {
  uint256 private constant PERCENT_DENOMENATOR = 1000;
  address private constant DEAD = address(0xdead);

  IERC20 lottoToken = IERC20(0xAAb679E21a9c73a02C9Ed33bbB6bb9E59f11afa9);
  uint256 public currentMinWinAmount;
  uint256 public percentageFeeWin = (PERCENT_DENOMENATOR * 95) / 100;
  uint256 public lottoEntryFee = 10**18; // 1 token (assuming 18 decimals)
  uint256 public lottoTimespan = 60 * 60 * 24; // 24 hours

  uint256[] public lotteries;
  // lottoTimestamp => isSettled
  mapping(uint256 => bool) public isLotterySettled;
  // lottoTimestamp => participants
  mapping(uint256 => address[]) public lottoParticipants;
  // lottoTimestamp => winner
  mapping(uint256 => address) public lottoWinners;
  // lottoTimestamp => amountWon
  mapping(uint256 => uint256) public lottoWinnerAmounts;

  mapping(uint256 => uint256) private _lotterySelectInit;
  mapping(uint256 => uint256) private _lotterySelectReqIdInit;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint32 private _vrfCallbackGasLimit = 600000;

  event DrawWinner(uint256 indexed lottoTimestamp);
  event SelectedWinner(
    uint256 indexed lottoTimestamp,
    address indexed winner,
    uint256 amountWon
  );

  constructor(
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function launch(uint256 _initAmount) external onlyOwner {
    depositIntoLottoPool(_initAmount);
    lotteries.push(block.timestamp);
  }

  function depositIntoLottoPool(uint256 _depositAmount) public {
    lottoToken.transferFrom(msg.sender, address(this), _depositAmount);
    currentMinWinAmount += _depositAmount;
  }

  function withdrawFromLottoPool(uint256 _amount) external onlyOwner {
    _amount = _amount > 0 ? _amount : currentMinWinAmount;
    lottoToken.transfer(owner(), _amount);
    currentMinWinAmount -= _amount;
  }

  function enterLotto(uint256 _entries) external {
    _enterLotto(msg.sender, msg.sender, _entries);
  }

  function enterLottoForUser(address _user, uint256 _entries) external {
    _enterLotto(msg.sender, _user, _entries);
  }

  function _enterLotto(
    address _payingUser,
    address _entryUser,
    uint256 _entries
  ) internal {
    uint256 _currentLottery = getCurrentLottery();
    if (block.timestamp > _currentLottery + lottoTimespan) {
      selectLottoWinner();
      _currentLottery = getCurrentLottery();
    }

    lottoToken.transferFrom(
      _payingUser,
      address(this),
      _entries * lottoEntryFee
    );
    for (uint256 i = 0; i < _entries; i++) {
      lottoParticipants[_currentLottery].push(_entryUser);
    }
  }

  function selectLottoWinner() public {
    uint256 _currentLottery = getCurrentLottery();
    require(
      block.timestamp > _currentLottery + lottoTimespan,
      'lottery time period must be past'
    );
    require(currentMinWinAmount > 0, 'no jackpot to win');
    require(_lotterySelectInit[_currentLottery] == 0, 'already initiated');
    lotteries.push(block.timestamp);

    if (lottoParticipants[_currentLottery].length == 0) {
      _lotterySelectInit[_currentLottery] = 1;
      isLotterySettled[_currentLottery] = true;
      return;
    }

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      uint16(3),
      _vrfCallbackGasLimit,
      uint16(1)
    );
    _lotterySelectInit[_currentLottery] = requestId;
    _lotterySelectReqIdInit[requestId] = _currentLottery;
    emit DrawWinner(_currentLottery);
  }

  function manualSettleLottery(uint256 requestId, uint256[] memory randomWords)
    external
    onlyOwner
  {
    _settleLottery(requestId, randomWords);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    _settleLottery(requestId, randomWords);
  }

  function _settleLottery(uint256 requestId, uint256[] memory randomWords)
    internal
  {
    uint256 _lotteryToSettle = _lotterySelectReqIdInit[requestId];
    require(_lotteryToSettle != 0, 'lottery selection does not exist');

    uint256 _winnerIdx = randomWords[0] %
      lottoParticipants[_lotteryToSettle].length;
    address _winner = lottoParticipants[_lotteryToSettle][_winnerIdx];

    uint256 _amountWon = getLotteryRewardAmount(_lotteryToSettle);
    lottoToken.transfer(_winner, _amountWon);
    if (_amountWon == currentMinWinAmount) {
      currentMinWinAmount =
        lottoParticipants[_lotteryToSettle].length *
        lottoEntryFee;
    }
    lottoWinners[_lotteryToSettle] = _winner;
    lottoWinnerAmounts[_lotteryToSettle] = _amountWon;
    isLotterySettled[_lotteryToSettle] = true;
    emit SelectedWinner(_lotteryToSettle, _winner, _amountWon);
  }

  function getLottoToken() external view returns (address) {
    return address(lottoToken);
  }

  function getCurrentLottery() public view returns (uint256) {
    return lotteries[lotteries.length - 1];
  }

  function getNumberLotteries() external view returns (uint256) {
    return lotteries.length;
  }

  function getCurrentLotteryRewardAmount() external view returns (uint256) {
    return getLotteryRewardAmount(getCurrentLottery());
  }

  function getLotteryRewardAmount(uint256 _lottery)
    public
    view
    returns (uint256)
  {
    uint256 _participants = getLotteryEntries(_lottery);
    uint256 _entryFeesTotal = _participants * lottoEntryFee;
    uint256 _entryFeeWinAmount = (_entryFeesTotal * percentageFeeWin) /
      PERCENT_DENOMENATOR;

    if (_entryFeeWinAmount < currentMinWinAmount) {
      return currentMinWinAmount;
    }
    return _entryFeeWinAmount;
  }

  function getCurrentLotteryEntries() external view returns (uint256) {
    return getLotteryEntries(getCurrentLottery());
  }

  function getLotteryEntries(uint256 _lottery) public view returns (uint256) {
    return lottoParticipants[_lottery].length;
  }

  function setPercentageFeeWin(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    require(_percent > 0, 'has to be more than 0%');
    percentageFeeWin = _percent;
  }

  function setLottoToken(address _token) external onlyOwner {
    lottoToken = IERC20(_token);
  }

  function setLottoTimespan(uint256 _seconds) external onlyOwner {
    lottoTimespan = _seconds;
  }

  function setLottoEntryFee(uint256 _fee) external onlyOwner {
    lottoEntryFee = _fee;
  }

  function withdrawTokens(address _tokenAddy, uint256 _amount)
    external
    onlyOwner
  {
    IERC20 _token = IERC20(_tokenAddy);
    _amount = _amount > 0 ? _amount : _token.balanceOf(address(this));
    require(_amount > 0, 'make sure there is a balance available to withdraw');
    _token.transfer(owner(), _amount);
  }
}
