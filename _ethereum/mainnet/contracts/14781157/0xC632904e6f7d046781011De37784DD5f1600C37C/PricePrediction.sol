// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./AggregatorProxy.sol";
import "./SmolGame.sol";

/**
 * @title PricePrediction
 * @dev Predict if price goes up or down over a time period
 */
contract PricePrediction is SmolGame {
  uint256 private constant PERCENT_DENOMENATOR = 1000;
  address private constant DEAD = address(0xdead);

  struct Prediction {
    address priceFeedProxy;
    uint256 startPriceUSD; // USD price w/ 18 decimals
    bool isLong; // true if price should go higher, otherwise price expected to go lower
    uint256 startBlock;
    uint256 startTimestamp;
    uint256 amountWagered;
    uint256 amountPayoutTotal;
    uint16 startPhaseId;
    uint80 startRoundId;
    uint16 endPhaseId; // not set until prediction is settled
    uint80 endRoundId; // not set until prediction is settled
    bool isDraw; // not set until prediction is settled
    bool isWinner; // not set until prediction is settled
  }

  uint256 public currentObligation;
  uint256 public payoutPercentage = (PERCENT_DENOMENATOR * 95) / 100;
  uint256 public minBalancePerc = (PERCENT_DENOMENATOR * 35) / 100; // 35% user's balance
  uint256 public minWagerAbsolute;

  address[] public validPriceFeedProxies;
  mapping(address => bool) public isValidPriceFeedProxy;

  uint256 public predictionTimePeriodSeconds = 60 * 60; // 1 hour

  address public wagerToken = 0xAAb679E21a9c73a02C9Ed33bbB6bb9E59f11afa9;
  IERC20 private wagerTokenContract = IERC20(wagerToken);

  uint256 public totalPredictionsMade;
  uint256 public totalPredictionsWon;
  uint256 public totalPredictionsLost;
  uint256 public totalPredictionsDraw;
  // user => predictions[]
  mapping(address => Prediction[]) public predictions;
  mapping(address => uint256) public predictionsUserWon;
  mapping(address => uint256) public predictionsUserLost;
  mapping(address => uint256) public predictionsUserDraw;
  mapping(address => uint256) public predictionsAmountUserWon;
  mapping(address => uint256) public predictionsAmountUserLost;

  event Predict(
    address indexed user,
    address indexed proxy,
    uint256 startBlock,
    uint256 startPrice,
    uint256 amountWager
  );
  event Settle(
    address indexed user,
    address indexed proxy,
    bool isWinner,
    bool isDraw,
    uint256 startBlock,
    uint256 amountWon
  );

  function getAllValidPriceFeeds() external view returns (address[] memory) {
    return validPriceFeedProxies;
  }

  function getNumberUserPredictions(address _user)
    external
    view
    returns (uint256)
  {
    return predictions[_user].length;
  }

  function getLatestUserPrediction(address _user)
    external
    view
    returns (Prediction memory)
  {
    require(predictions[_user].length > 0, 'no predictions for user');
    return predictions[_user][predictions[_user].length - 1];
  }

  /**
   * Returns the latest price with returned value from a price feed proxy at 18 decimals
   * more info (proxy vs agg) here:
   * https://stackoverflow.com/questions/70377502/what-is-the-best-way-to-access-historical-price-data-from-chainlink-on-a-token-i/70389049#70389049
   *
   * https://docs.chain.link/docs/get-the-latest-price/
   */
  function getRoundInfoAndPriceUSD(address _proxy)
    public
    view
    returns (
      uint16,
      uint80,
      uint256
    )
  {
    // https://docs.chain.link/docs/reference-contracts/
    // https://github.com/pcaversaccio/chainlink-price-feed/blob/main/README.md
    AggregatorProxy priceFeed = AggregatorProxy(_proxy);
    uint16 phaseId = priceFeed.phaseId();
    uint8 decimals = priceFeed.decimals();
    (uint80 proxyRoundId, int256 price, , , ) = priceFeed.latestRoundData();
    return (phaseId, proxyRoundId, uint256(price) * (10**18 / 10**decimals));
  }

  function getPriceUSDAtRound(address _proxy, uint80 _roundId)
    public
    view
    returns (uint256)
  {
    AggregatorProxy priceFeed = AggregatorProxy(_proxy);
    uint8 decimals = priceFeed.decimals();
    (, int256 price, , , ) = priceFeed.getRoundData(_roundId);
    return uint256(price) * (10**18 / 10**decimals);
  }

  // https://docs.chain.link/docs/historical-price-data/
  function getHistoricalPriceFromAggregatorInfo(
    address _proxy,
    uint16 _phaseId,
    uint80 _aggRoundId
  )
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint80
    )
  {
    AggregatorProxy proxy = AggregatorProxy(_proxy);
    uint80 _proxyRoundId = _getProxyRoundId(_phaseId, _aggRoundId);
    (
      uint80 roundId,
      int256 price,
      ,
      uint256 timestamp,
      uint80 answeredInRound
    ) = proxy.getRoundData(_proxyRoundId);
    require(timestamp > 0, 'Round not complete');
    return (roundId, price, timestamp, answeredInRound);
  }

  // _isLong: if true, user wants price to go up, else price should go down
  function predict(
    address _priceFeedProxy,
    uint256 _amountWager,
    bool _isLong
  ) external payable {
    require(
      isValidPriceFeedProxy[_priceFeedProxy],
      'not a valid price feed to predict'
    );
    require(
      _amountWager >=
        (wagerTokenContract.balanceOf(msg.sender) * minBalancePerc) /
          PERCENT_DENOMENATOR,
      'did not wager enough of balance'
    );
    require(_amountWager >= minWagerAbsolute, 'did not wager at least minimum');

    _payServiceFee();
    address _user = msg.sender;
    if (predictions[_user].length > 0) {
      Prediction memory _openPrediction = predictions[_user][
        predictions[_user].length - 1
      ];
      require(
        _openPrediction.endRoundId > 0,
        'there is an open prediction you must settle before creating a new one'
      );
    }

    wagerTokenContract.transferFrom(msg.sender, address(this), _amountWager);
    uint256 _finalPayout = _amountWager +
      ((_amountWager * payoutPercentage) / PERCENT_DENOMENATOR);
    (
      uint16 _phaseId,
      uint80 _roundId,
      uint256 _currentPrice
    ) = getRoundInfoAndPriceUSD(_priceFeedProxy);
    Prediction memory _newPrediction = Prediction({
      priceFeedProxy: _priceFeedProxy,
      startPriceUSD: _currentPrice,
      isLong: _isLong,
      startBlock: block.number,
      startTimestamp: block.timestamp,
      amountWagered: _amountWager,
      amountPayoutTotal: _finalPayout,
      startPhaseId: _phaseId,
      startRoundId: _roundId,
      endPhaseId: 0,
      endRoundId: 0,
      isDraw: false,
      isWinner: false
    });
    predictions[_user].push(_newPrediction);

    currentObligation += _finalPayout;
    require(
      currentObligation <= wagerTokenContract.balanceOf(address(this)),
      'not enough liquidity to pay prediction out'
    );

    totalPredictionsMade++;
    emit Predict(
      msg.sender,
      _priceFeedProxy,
      block.number,
      _currentPrice,
      _amountWager
    );
  }

  // in order to settle an open prediction, the settling executor must know the
  // user with the open prediction they are settling and the round ID that corresponds
  // to the time it should be settled.
  function settlePrediction(
    address _user,
    uint16 _answeredPhaseId,
    uint80 _answeredAggRoundId
  ) public {
    _user = _user == address(0) ? msg.sender : _user;
    require(predictions[_user].length > 0, 'no predictions created yet');
    Prediction storage _openPrediction = predictions[_user][
      predictions[_user].length - 1
    ];
    require(
      _openPrediction.priceFeedProxy != address(0),
      'no predictions created yet to settle'
    );
    require(
      _openPrediction.endRoundId == 0,
      'latest prediction already settled'
    );

    (
      uint80 roundActual,
      ,
      uint256 timestampActual,
      uint80 answeredInRoundActual
    ) = getHistoricalPriceFromAggregatorInfo(
        _openPrediction.priceFeedProxy,
        _answeredPhaseId,
        _answeredAggRoundId
      );
    (, , uint256 timestampAfter, ) = getHistoricalPriceFromAggregatorInfo(
      _openPrediction.priceFeedProxy,
      _answeredPhaseId,
      _answeredAggRoundId + 1
    );
    require(
      roundActual == answeredInRoundActual,
      'actual round not finished yet'
    );
    require(
      timestampActual <=
        _openPrediction.startTimestamp + predictionTimePeriodSeconds,
      'actual round was completed after our time period'
    );
    require(
      timestampAfter >
        _openPrediction.startTimestamp + predictionTimePeriodSeconds ||
        (timestampAfter == 0 &&
          block.timestamp >
          _openPrediction.startTimestamp + predictionTimePeriodSeconds),
      'after round was completed before our time period'
    );

    uint256 settlePrice = getPriceUSDAtRound(
      _openPrediction.priceFeedProxy,
      roundActual
    );

    bool _isDraw = settlePrice == _openPrediction.startPriceUSD;
    bool _isWinner = false;
    if (!_isDraw) {
      _isWinner = _openPrediction.isLong
        ? settlePrice > _openPrediction.startPriceUSD
        : settlePrice < _openPrediction.startPriceUSD;
    }

    _openPrediction.endPhaseId = _answeredPhaseId;
    _openPrediction.endRoundId = roundActual;
    _openPrediction.isDraw = _isDraw;
    _openPrediction.isWinner = _isWinner;

    uint256 _finalAmountTransfer = _isDraw
      ? _openPrediction.amountWagered
      : _isWinner
      ? _openPrediction.amountPayoutTotal
      : 0;
    if (_finalAmountTransfer > 0) {
      wagerTokenContract.transfer(_user, _finalAmountTransfer);
    }
    currentObligation -= _openPrediction.amountPayoutTotal;

    totalPredictionsWon += _isWinner ? 1 : 0;
    predictionsUserWon[_user] += _isWinner ? 1 : 0;
    totalPredictionsLost += !_isWinner && !_isDraw ? 1 : 0;
    predictionsUserLost[_user] += !_isWinner && !_isDraw ? 1 : 0;
    totalPredictionsDraw += _isDraw ? 1 : 0;
    predictionsUserDraw[_user] += _isDraw ? 1 : 0;
    predictionsAmountUserWon[_user] += _isWinner
      ? _finalAmountTransfer - _openPrediction.amountWagered
      : 0;
    predictionsAmountUserLost[_user] += !_isWinner && !_isDraw
      ? _openPrediction.amountWagered
      : 0;

    emit Settle(
      _user,
      _openPrediction.priceFeedProxy,
      _isWinner,
      _isDraw,
      _openPrediction.startBlock,
      _finalAmountTransfer
    );
  }

  function settleMultiplePredictions(
    address[] memory _users,
    uint16[] memory _phaseIds,
    uint80[] memory _aggRoundIds
  ) external {
    require(_users.length == _phaseIds.length, 'need to be same size arrays');
    require(
      _users.length == _aggRoundIds.length,
      'need to be same size arrays'
    );
    for (uint256 i = 0; i < _users.length; i++) {
      settlePrediction(_users[i], _phaseIds[i], _aggRoundIds[i]);
    }
  }

  function _getProxyRoundId(uint16 _phaseId, uint80 _aggRoundId)
    internal
    pure
    returns (uint80)
  {
    return uint80((uint256(_phaseId) << 64) | _aggRoundId);
  }

  function getAggregatorPhaseAndRoundId(uint256 _proxyRoundId)
    external
    pure
    returns (uint16, uint64)
  {
    uint16 phaseId = uint16(_proxyRoundId >> 64);
    uint64 aggregatorRoundId = uint64(_proxyRoundId);
    return (phaseId, aggregatorRoundId);
  }

  function setMinBalancePerc(uint256 _perc) external onlyOwner {
    require(_perc <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    minBalancePerc = _perc;
  }

  function setMinWagerAbsolute(uint256 _amount) external onlyOwner {
    minWagerAbsolute = _amount;
  }

  function setPredictionTimePeriodSeconds(uint256 _seconds) external onlyOwner {
    require(_seconds > 60, 'must be longer than 60 seconds');
    predictionTimePeriodSeconds = _seconds;
  }

  function setPayoutPercentage(uint256 _percentage) external onlyOwner {
    require(_percentage <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    payoutPercentage = _percentage;
  }

  function setWagerToken(address _token) external onlyOwner {
    wagerToken = _token;
    wagerTokenContract = IERC20(_token);
  }

  function addPriceFeed(address _proxy) external onlyOwner {
    for (uint256 i = 0; i < validPriceFeedProxies.length; i++) {
      if (validPriceFeedProxies[i] == _proxy) {
        require(false, 'price feed already in feed list');
      }
    }
    isValidPriceFeedProxy[_proxy] = true;
    validPriceFeedProxies.push(_proxy);
  }

  function removePriceFeed(address _proxy) external onlyOwner {
    for (uint256 i = 0; i < validPriceFeedProxies.length; i++) {
      if (validPriceFeedProxies[i] == _proxy) {
        delete isValidPriceFeedProxy[_proxy];
        validPriceFeedProxies[i] = validPriceFeedProxies[
          validPriceFeedProxies.length - 1
        ];
        validPriceFeedProxies.pop();
        break;
      }
    }
  }
}
