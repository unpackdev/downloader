// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./KeeperCompatible.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IFeeReducer.sol";
import "./IBokkyPooBahsDateTime.sol";
import "./IndexHandler.sol";
import "./pfYDF.sol";

contract PerpetualFutures is IndexHandler, KeeperCompatibleInterface, Ownable {
  using SafeERC20 for ERC20;

  uint256 constant PERC_DEN = 100000;

  pfYDF perpsNft;
  IFeeReducer feeReducer;
  IBokkyPooBahsDateTime timeLibrary =
    IBokkyPooBahsDateTime(0x23d23d8F243e57d0b924bff3A3191078Af325101);

  bool public tradingEnabled;

  mapping(address => bool) public settlers;
  uint8 maxLiquidationsPerUpkeep = 25;

  address public mainCollateralToken =
    0x30dcBa0405004cF124045793E1933C798Af9E66a;
  mapping(address => bool) _validColl;
  address[] _allCollTokens;
  mapping(address => uint256) _allCollTokensInd;

  uint16 public maxLeverage = 500; // 50x
  uint8 public maxTriggerOrders = 2;
  uint256 public minOpenTimeForProfit = 3 hours;
  uint256 public minPriceDiffForProfit = (PERC_DEN * 15) / 1000; // 1.5%
  uint256 public openFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closeFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closeFeePerDurationUnit = 1 hours;
  uint256 public closeFeePerDuration = (PERC_DEN * 5) / 100000; // 0.005% / hour

  // collateral token => amount
  mapping(address => uint256) public amtOpenLong;
  mapping(address => uint256) public amtOpenShort;
  mapping(address => uint256) public maxCollateralOpenDiff;

  struct PositionIndexFeed {
    IndexFeed feed;
    uint16 phaseIdStart;
    uint80 roundIdStart;
    uint16 phaseIdSettle;
    uint80 roundIdSettle;
  }

  struct TriggerOrder {
    uint256 idxPriceCurrent;
    uint256 idxPriceTarget;
  }

  struct PositionLifecycle {
    uint256 openTime;
    uint256 openFees;
    uint256 closeTime;
    uint256 closeFees;
    uint256 settleCollPriceUSD; // For positions with alternate collateral, USD per collateral token extended to 18 decimals
    uint256 settleMainPriceUSD; // For positions with alternate collateral, USD per main token extended to 18 decimals
  }

  struct Position {
    PositionIndexFeed[] feeds;
    PositionLifecycle lifecycle;
    address collateralToken;
    uint256 collateralCloseUnsettled;
    uint256 collateralAmount;
    uint256 positionAmount;
    bool isLong;
    uint16 leverage;
    uint256 indexPriceStart;
    uint256 indexPriceSettle;
    uint256 amountWon;
    uint256 amountLost;
    bool isSettled;
  }

  // tokenId => Position
  mapping(uint256 => Position) public positions;
  // tokenId => address
  mapping(uint256 => address) public positionOpeners;
  // tokenId => address
  mapping(uint256 => address) public positionClosers;
  // tokenId => orders
  mapping(uint256 => TriggerOrder[]) public positionTriggerOrders;
  // tokenId[]
  uint256[] public allOpenPositions;
  // tokenId => allOpenPositions index
  mapping(uint256 => uint256) internal _openPositionsIdx;
  // tokenId[]
  uint256[] public allUnsettledPositions;
  // tokenId => allUnsettledPositions index
  mapping(uint256 => uint256) internal _unsettledPositionsIdx;

  event CloseUnsettledPosition(uint256 indexed tokenId);
  event OpenPosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 positionCollateral,
    bool isLong,
    uint256 leverage
  );
  event ClosePosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 indexPriceSettle,
    uint256 amountWon,
    uint256 amountLost
  );
  event LiquidatePosition(uint256 tokenId);
  event ClosePositionFromTriggerOrder(uint256 tokenId);
  event SettlePosition(
    uint256 tokenId,
    uint256 mainTokenSettleAmt,
    uint256 collSettlePrice,
    uint256 mainSettlePrice
  );

  modifier onlyPositionOwner(uint256 _tokenId) {
    require(msg.sender == perpsNft.ownerOf(_tokenId), 'must own position');
    _;
  }

  modifier onlySettler() {
    require(settlers[msg.sender], 'only settlers');
    _;
  }

  constructor(string memory _tokenURI) {
    perpsNft = new pfYDF(_tokenURI);
    perpsNft.transferOwnership(msg.sender);
  }

  function getFeeReducer() external view returns (address) {
    return address(feeReducer);
  }

  function getPerpsNFT() external view returns (address) {
    return address(perpsNft);
  }

  function getAllIndexes() external view returns (Index[] memory) {
    return indexes;
  }

  function getAllValidCollateralTokens()
    external
    view
    returns (address[] memory)
  {
    return _allCollTokens;
  }

  function getAllUnsettledPositions() external view returns (uint256[] memory) {
    return allUnsettledPositions;
  }

  function getAllPositionTriggerOrders(uint256 _tokenId)
    external
    view
    returns (TriggerOrder[] memory)
  {
    return positionTriggerOrders[_tokenId];
  }

  function openPosition(
    address _collToken,
    uint256 _indexInd,
    uint256 _desiredPrice,
    uint256 _slippage, // 1 == 0.1%, 10 == 1%
    uint256 _collateral,
    uint16 _leverage, // 10 == 1x, 1000 == 100x
    bool _isLong,
    uint256 _triggerOrderTargetPrice
  ) external payable {
    require(tradingEnabled, 'DISABLED');
    require(_indexInd < indexes.length, 'INVIDX');
    require(_leverage >= 10 && _leverage <= maxLeverage, 'LEV1');
    require(_canOpenAgainstIndex(_indexInd, 0), 'INDOOB1');
    require(
      _collToken == address(0) ||
        _collToken == mainCollateralToken ||
        _validColl[_collToken],
      'POSTOKEN1'
    );

    uint256 _newTokenId = perpsNft.mint(msg.sender);
    (uint256 _openFee, uint256 _finalCollateral) = _processOpenCollateral(
      msg.sender,
      _collToken,
      _collateral,
      _leverage
    );

    Position storage _newPosition = _createNewPosition(_indexInd, _newTokenId);
    uint256 _openPrice = getIndexPriceFromIndex(_indexInd);
    _validateOpenPriceSlip(_desiredPrice, _openPrice, _slippage, _isLong);

    positionOpeners[_newTokenId] = msg.sender;
    _newPosition.lifecycle.openTime = block.timestamp;
    _newPosition.lifecycle.openFees = _openFee;
    _newPosition.collateralAmount = _finalCollateral;
    _newPosition.positionAmount = (_finalCollateral * _leverage) / 10;
    _newPosition.isLong = _isLong;
    _newPosition.leverage = _leverage;
    _newPosition.indexPriceStart = _openPrice;
    _newPosition.collateralToken = _collToken;

    _addOpenPosition(_newTokenId);
    _validateAndUpdateOpenAmounts(_newTokenId, _newPosition.positionAmount);
    if (_triggerOrderTargetPrice > 0) {
      _addTriggerOrder(_newTokenId, _triggerOrderTargetPrice);
    }

    emit OpenPosition(
      _newTokenId,
      msg.sender,
      _openPrice,
      _finalCollateral,
      _isLong,
      _leverage
    );
  }

  function _processOpenCollateral(
    address _user,
    address _collToken,
    uint256 _collateral,
    uint256 _leverage
  ) internal returns (uint256, uint256) {
    uint256 _openFee;
    uint256 _finalCollateral;

    // native token
    if (_collToken == address(0)) {
      require(msg.value > 0, 'COLL3');
      _collateral = msg.value;
      _openFee = _getPositionOpenFee(_user, _collateral, _leverage);
      _finalCollateral = _collateral - _openFee;
    } else {
      ERC20 _collCont = ERC20(_collToken);
      require(_collCont.balanceOf(_user) >= _collateral, 'BAL1');

      uint256 _before = _collCont.balanceOf(address(this));
      _collCont.safeTransferFrom(_user, address(this), _collateral);
      _collateral = _collCont.balanceOf(address(this)) - _before;
      _openFee = _getPositionOpenFee(_user, _collateral, _leverage);
      _finalCollateral = _collateral - _openFee;
    }
    return (_openFee, _finalCollateral);
  }

  function _validateOpenPriceSlip(
    uint256 _desiredPrice,
    uint256 _currentPrice,
    uint256 _slippage, // 1 == 0.1%, 10 == 1%
    bool _isLong
  ) internal pure {
    uint256 _idxSlipDiff;
    if (_isLong && _currentPrice > _desiredPrice) {
      _idxSlipDiff = _currentPrice - _desiredPrice;
    } else if (!_isLong && _desiredPrice > _currentPrice) {
      _idxSlipDiff = _desiredPrice - _currentPrice;
    }
    if (_idxSlipDiff > 0) {
      require(
        (_idxSlipDiff * FACTOR) / _desiredPrice <= (_slippage * FACTOR) / 1000,
        'SLIPPAGE'
      );
    }
  }

  function _createNewPosition(uint256 _indexInd, uint256 _tokenId)
    internal
    returns (Position storage)
  {
    Position storage _newPosition = positions[_tokenId];
    for (uint256 _i = 0; _i < indexes[_indexInd].priceFeeds.length; _i++) {
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(
        indexes[_indexInd].priceFeeds[_i].proxy
      );
      _newPosition.feeds.push(
        PositionIndexFeed({
          feed: indexes[_indexInd].priceFeeds[_i],
          phaseIdStart: _phase,
          roundIdStart: _round,
          phaseIdSettle: 0,
          roundIdSettle: 0
        })
      );
    }
    return _newPosition;
  }

  function _canOpenAgainstIndex(uint256 _ind, uint256 _timestamp)
    internal
    view
    returns (bool)
  {
    return
      _doTimeBoundsPass(
        _timestamp,
        indexes[_ind].dowOpenMin,
        indexes[_ind].dowOpenMax,
        indexes[_ind].hourOpenMin,
        indexes[_ind].hourOpenMax
      );
  }

  function _doTimeBoundsPass(
    uint256 _timestamp,
    uint256 _dowOpenMin,
    uint256 _dowOpenMax,
    uint256 _hourOpenMin,
    uint256 _hourOpenMax
  ) internal view returns (bool) {
    _timestamp = _timestamp == 0 ? block.timestamp : _timestamp;
    if (_dowOpenMin >= 1 && _dowOpenMax >= 1) {
      uint256 _dow = timeLibrary.getDayOfWeek(_timestamp);
      if (_dow < _dowOpenMin || _dow > _dowOpenMax) {
        return false;
      }
    }
    if (_hourOpenMin >= 1 || _hourOpenMax >= 1) {
      uint256 _hour = timeLibrary.getHour(_timestamp);
      if (_hour < _hourOpenMin || _hour > _hourOpenMax) {
        return false;
      }
    }
    return true;
  }

  function closePosition(uint256 _tokenId) external {
    _closePosition(_tokenId, false);
  }

  function _closePosition(uint256 _tokenId, bool _overrideOwner) internal {
    address _user = perpsNft.ownerOf(_tokenId);

    require(_overrideOwner || msg.sender == _user, 'OWNLQ');
    require(perpsNft.doesTokenExist(_tokenId), 'CLOSE1');

    _getAndClosePositionPLInfo(_tokenId, _user);
    _removeOpenPosition(_tokenId);
    _closeIndividualFeeds(_tokenId);
    _updateCloseAmounts(_tokenId);
    perpsNft.burn(_tokenId);

    positionClosers[_tokenId] = _user;

    emit ClosePosition(
      _tokenId,
      _user,
      positions[_tokenId].indexPriceStart,
      positions[_tokenId].indexPriceSettle,
      positions[_tokenId].amountWon,
      positions[_tokenId].amountLost
    );
  }

  function settleUnsettledPosition(
    uint256 _tokenId,
    uint256 _collPriceUSD,
    uint256 _mainPriceUSD
  ) external onlySettler {
    Position storage _position = positions[_tokenId];
    require(!_position.isSettled, 'SET1');
    require(_position.collateralCloseUnsettled > 0, 'SET2');

    _position.isSettled = true;
    _position.lifecycle.settleCollPriceUSD = _collPriceUSD;
    _position.lifecycle.settleMainPriceUSD = _mainPriceUSD;
    uint256 _mainSettleAmt = (_position.collateralCloseUnsettled *
      10**ERC20(mainCollateralToken).decimals() *
      _collPriceUSD) /
      _mainPriceUSD /
      10**ERC20(_position.collateralToken).decimals();
    ERC20(mainCollateralToken).safeTransfer(
      positionClosers[_tokenId],
      _mainSettleAmt
    );

    // remove from unsettled positions array
    uint256 _unsetPositionsIdx = _unsettledPositionsIdx[_tokenId];
    uint256 _tokenIdMoving = allUnsettledPositions[
      allUnsettledPositions.length - 1
    ];
    delete _unsettledPositionsIdx[_tokenId];
    _unsettledPositionsIdx[_tokenIdMoving] = _unsetPositionsIdx;
    allUnsettledPositions[_unsetPositionsIdx] = _tokenIdMoving;
    allUnsettledPositions.pop();

    emit SettlePosition(_tokenId, _mainSettleAmt, _collPriceUSD, _mainPriceUSD);
  }

  function getIndexAndPLInfo(uint256 _tokenId)
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      bool,
      bool
    )
  {
    Position memory _position = positions[_tokenId];
    bool _canCloseInProfit = true;
    uint256 _currentIndexPrice = getPositionIndexPrice(_tokenId);
    bool _settlePriceIsHigher = _currentIndexPrice > _position.indexPriceStart;
    bool _settlePriceIsLower = _currentIndexPrice < _position.indexPriceStart;
    uint256 _indexAbsDiffFromOpen = _settlePriceIsHigher
      ? _currentIndexPrice - _position.indexPriceStart
      : _position.indexPriceStart - _currentIndexPrice;
    uint256 _absolutePL = (_position.positionAmount * _indexAbsDiffFromOpen) /
      _position.indexPriceStart;
    bool _isProfit = _position.isLong
      ? _settlePriceIsHigher
      : _settlePriceIsLower;

    uint256 _amountReturnToUser = _position.collateralAmount;
    if (_isProfit) {
      bool _isOverMinChange = _indexAbsDiffFromOpen >=
        (_position.indexPriceStart * minPriceDiffForProfit) / PERC_DEN;
      bool _isPastMinTime = block.timestamp >=
        _position.lifecycle.openTime + minOpenTimeForProfit;
      if (_isOverMinChange || _isPastMinTime) {
        _amountReturnToUser += _absolutePL;
      } else {
        _canCloseInProfit = false;
      }
    } else {
      if (_absolutePL > _amountReturnToUser) {
        _amountReturnToUser = 0;
      } else {
        _amountReturnToUser -= _absolutePL;
      }
    }
    return (
      _currentIndexPrice,
      _amountReturnToUser,
      _absolutePL,
      _isProfit,
      _canCloseInProfit
    );
  }

  function getLiquidationPriceChange(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    // 90% of exact liquidation which would mean 100% deliquency
    // NOTE: _position.leverage == 10 means 1x
    // Ex. price start == 100, leverage == 15 (1.5x)
    // (priceStart / (15 / 10)) * (9 / 10)
    // (priceStart * 10 / 15) * (9 / 10)
    // (priceStart / 15) * 9
    // (priceStart * 9) / 15
    return
      (positions[_tokenId].indexPriceStart * 9) / positions[_tokenId].leverage;
  }

  function getPositionIndexPrice(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    address[] memory _proxies = new address[](positions[_tokenId].feeds.length);
    uint256[] memory _multipliers = new uint256[](
      positions[_tokenId].feeds.length
    );
    for (uint256 _i = 0; _i < positions[_tokenId].feeds.length; _i++) {
      _proxies[_i] = positions[_tokenId].feeds[_i].feed.proxy;
      _multipliers[_i] = positions[_tokenId].feeds[_i].feed.priceWeightMult;
    }
    return getIndexPriceFromFeeds(_proxies, _multipliers);
  }

  function getPositionCloseFees(uint256 _tokenId)
    public
    view
    returns (uint256, uint256)
  {
    address _owner = perpsNft.ownerOf(_tokenId);
    (uint256 _percentOff, uint256 _percOffDenomenator) = getFeeDiscount(_owner);
    uint256 _closingFeePosition = (positions[_tokenId].positionAmount *
      closeFeePositionSize) / PERC_DEN;
    uint256 _closingFeeDurationPerUnit = (positions[_tokenId].positionAmount *
      closeFeePerDuration) / PERC_DEN;
    uint256 _closingFeeDurationTotal = (_closingFeeDurationPerUnit *
      (block.timestamp - positions[_tokenId].lifecycle.openTime)) /
      closeFeePerDurationUnit;

    // user has discount from fees
    if (_percentOff > 0) {
      _closingFeePosition -=
        (_closingFeePosition * _percentOff) /
        _percOffDenomenator;
      _closingFeeDurationTotal -=
        (_closingFeeDurationTotal * _percentOff) /
        _percOffDenomenator;
    }
    return (_closingFeePosition, _closingFeeDurationTotal);
  }

  function getPositionIndexProxies(uint256 _tokenId)
    external
    view
    returns (address[] memory)
  {
    address[] memory _proxies = new address[](positions[_tokenId].feeds.length);
    for (uint256 _i = 0; _i < positions[_tokenId].feeds.length; _i++) {
      _proxies[_i] = positions[_tokenId].feeds[_i].feed.proxy;
    }
    return _proxies;
  }

  function addTriggerOrder(uint256 _tokenId, uint256 _idxPriceTarget)
    external
    onlyPositionOwner(_tokenId)
  {
    _addTriggerOrder(_tokenId, _idxPriceTarget);
  }

  function updateTriggerOrder(
    uint256 _tokenId,
    uint256 _idx,
    uint256 _idxPriceTarget
  ) external onlyPositionOwner(_tokenId) {
    _updateTriggerOrder(_tokenId, _idx, _idxPriceTarget);
  }

  function removeTriggerOrder(uint256 _tokenId, uint256 _idx)
    external
    onlyPositionOwner(_tokenId)
  {
    _removeTriggerOrder(_tokenId, _idx);
  }

  function _addTriggerOrder(uint256 _tokenId, uint256 _idxPriceTarget)
    internal
  {
    require(_idxPriceTarget > 0, 'TO0');
    require(positionTriggerOrders[_tokenId].length < maxTriggerOrders, 'TO1');
    uint256 _idxPriceCurr = getPositionIndexPrice(_tokenId);
    require(_idxPriceCurr != _idxPriceTarget, 'TO2');

    positionTriggerOrders[_tokenId].push(
      TriggerOrder({
        idxPriceCurrent: _idxPriceCurr,
        idxPriceTarget: _idxPriceTarget
      })
    );
  }

  function _updateTriggerOrder(
    uint256 _tokenId,
    uint256 _idx,
    uint256 _idxTargetPrice
  ) internal {
    require(_idxTargetPrice > 0, 'TO0');

    TriggerOrder storage _order = positionTriggerOrders[_tokenId][_idx];
    bool _isTargetLess = _order.idxPriceTarget < _order.idxPriceCurrent;
    // if original target is less than original current, new target must
    // remain less than, or vice versa for higher than prices
    require(
      _isTargetLess
        ? _idxTargetPrice < _order.idxPriceCurrent
        : _idxTargetPrice > _order.idxPriceCurrent,
      'TO3'
    );
    _order.idxPriceTarget = _idxTargetPrice;
  }

  function _removeTriggerOrder(uint256 _tokenId, uint256 _idx) internal {
    positionTriggerOrders[_tokenId][_idx] = positionTriggerOrders[_tokenId][
      positionTriggerOrders[_tokenId].length - 1
    ];
    positionTriggerOrders[_tokenId].pop();
  }

  function setValidCollateralToken(address _token, bool _isValid)
    external
    onlyOwner
  {
    require(_validColl[_token] != _isValid, 'change state');
    _validColl[_token] = _isValid;
    if (_isValid) {
      _allCollTokensInd[_token] = _allCollTokens.length;
      _allCollTokens.push(_token);
    } else {
      uint256 _ind = _allCollTokensInd[_token];
      delete _allCollTokensInd[_token];
      _allCollTokens[_ind] = _allCollTokens[_allCollTokens.length - 1];
      _allCollTokens.pop();
    }
  }

  function setMainCollateralToken(address _token) external onlyOwner {
    require(allOpenPositions.length == 0, 'MAINCOLL');
    mainCollateralToken = _token;
  }

  // 10 == 1x, 1000 == 100x, etc.
  function setMaxLeverage(uint16 _max) external onlyOwner {
    require(_max <= 2500, 'max 250x');
    maxLeverage = _max;
  }

  function setMaxTriggerOrders(uint8 _max) external onlyOwner {
    maxTriggerOrders = _max;
  }

  function setMinOpenTimeForProfit(uint256 _seconds) external onlyOwner {
    require(_seconds <= 1 days, 'max 1 days');
    minOpenTimeForProfit = _seconds;
  }

  function setMinPriceDiffForProfit(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 3) / 100, 'max 3%');
    minPriceDiffForProfit = _percentage;
  }

  function setOpenFeePositionSize(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 10) / 100, 'max 10%');
    openFeePositionSize = _percentage;
  }

  function setCloseFeePositionSize(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 10) / 100, 'max 10%');
    closeFeePositionSize = _percentage;
  }

  function setCloseFeePositionPerDurationUnit(uint256 _seconds)
    external
    onlyOwner
  {
    require(_seconds >= 10 minutes, 'min 10m');
    closeFeePerDurationUnit = _seconds;
  }

  function setClosePositionFeePerDuration(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 1) / 100, 'max 1%');
    closeFeePerDuration = _percentage;
  }

  function setSettler(address _wallet, bool _isSettler) external onlyOwner {
    require(settlers[_wallet] != _isSettler, 'SET3');
    settlers[_wallet] = _isSettler;
  }

  function setMaxCollateralOpenDiff(address _collateral, uint256 _amount)
    external
    onlyOwner
  {
    maxCollateralOpenDiff[_collateral] = _amount;
  }

  function setMaxLiquidationsPerUpkeep(uint8 _max) external onlyOwner {
    require(_max > 0, 'min 1');
    maxLiquidationsPerUpkeep = _max;
  }

  function addIndex(
    string memory _name,
    address[] memory _proxies,
    uint16[] memory _weights
  ) external onlyOwner {
    require(
      _proxies.length > 0 && _proxies.length == _weights.length,
      'same len'
    );
    Index storage _newIndex = indexes.push();
    _newIndex.name = _name;

    for (uint256 _i = 0; _i < _proxies.length; _i++) {
      address _proxy = _proxies[_i];
      (, , uint256 _priceUSD) = getLatestProxyInfo(_proxy);
      require(_priceUSD > 0, 'invalid proxy');

      _newIndex.weightsTotal += _proxies.length == 1 ? 0 : _weights[_i];
      _newIndex.priceFeeds.push(
        IndexFeed({
          proxy: _proxy,
          weight: _weights[_i],
          priceWeightMult: _proxies.length == 1
            ? 0
            : (_weights[_i] * FACTOR**2) / _priceUSD
        })
      );
    }
  }

  function removeIndex(uint256 _index) external onlyOwner {
    indexes[_index] = indexes[indexes.length - 1];
    indexes.pop();
  }

  function refreshIndexFeedWeights(uint256 _indexIdx) external onlyOwner {
    Index storage _index = indexes[_indexIdx];
    require(_index.priceFeeds.length > 1, 'ISIDX');
    for (uint256 _i = 0; _i < _index.priceFeeds.length; _i++) {
      (, , uint256 _priceUSD) = getLatestProxyInfo(_index.priceFeeds[_i].proxy);
      _index.priceFeeds[_i].priceWeightMult =
        (_index.priceFeeds[_i].weight * FACTOR**2) /
        _priceUSD;
    }
  }

  function updateIndexOpenTimeBounds(
    uint256 _indexInd,
    uint256 _dowOpenMin,
    uint256 _dowOpenMax,
    uint256 _hourOpenMin,
    uint256 _hourOpenMax
  ) external onlyOwner {
    Index storage _index = indexes[_indexInd];
    _index.dowOpenMin = _dowOpenMin;
    _index.dowOpenMax = _dowOpenMax;
    _index.hourOpenMin = _hourOpenMin;
    _index.hourOpenMax = _hourOpenMax;
  }

  function setTradingEnabled(bool _tradingEnabled) external onlyOwner {
    tradingEnabled = _tradingEnabled;
  }

  function setFeeReducer(address _reducer) external onlyOwner {
    feeReducer = IFeeReducer(_reducer);
  }

  function processFees(uint256 _amount) external onlyOwner {
    ERC20(mainCollateralToken).safeTransfer(mainCollateralToken, _amount);
  }

  function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
    ERC20 _contract = ERC20(_token);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0);
    _contract.safeTransfer(owner(), _amount);
  }

  // https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/
  function checkUpkeep(
    bytes calldata /* checkData */
  )
    external
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    for (uint256 _i = 0; _i < allOpenPositions.length; _i++) {
      uint256 _tokenId = allOpenPositions[_i];
      if (
        shouldPositionLiquidate(_tokenId) ||
        shouldPositionCloseFromTrigger(_tokenId)
      ) {
        upkeepNeeded = true;
        break;
      }
    }
  }

  // https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/
  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    uint8 _liquidations;
    for (uint256 _i = 0; _i < allOpenPositions.length; _i++) {
      uint256 _tokenId = allOpenPositions[_i];
      bool _wasLiquidated = checkAndLiquidatePosition(_tokenId);
      if (_wasLiquidated) {
        _liquidations++;
        if (_liquidations >= maxLiquidationsPerUpkeep) {
          break;
        }
      }
    }
  }

  function checkAndLiquidatePosition(uint256 _tokenId) public returns (bool) {
    bool _shouldLiquidate = shouldPositionLiquidate(_tokenId);
    bool _triggerClose = shouldPositionCloseFromTrigger(_tokenId);
    if (_shouldLiquidate || _triggerClose) {
      _closePosition(_tokenId, true);

      if (_shouldLiquidate) {
        emit LiquidatePosition(_tokenId);
      } else if (_triggerClose) {
        emit ClosePositionFromTriggerOrder(_tokenId);
      }
      return true;
    }
    return false;
  }

  function getFeeDiscount(address _wallet)
    public
    view
    returns (uint256, uint256)
  {
    return
      address(feeReducer) != address(0)
        ? feeReducer.percentDiscount(_wallet)
        : (0, 0);
  }

  function _getPositionOpenFee(
    address _user,
    uint256 _collateral,
    uint256 _leverage
  ) internal view returns (uint256) {
    uint256 _positionPreFee = (_collateral * _leverage) / 10;
    uint256 _openFee = (_positionPreFee * openFeePositionSize) / PERC_DEN;
    (uint256 _percentOff, uint256 _percOffDenomenator) = getFeeDiscount(_user);
    // user has discount from fees
    if (_percentOff > 0) {
      _openFee -= (_openFee * _percentOff) / _percOffDenomenator;
    }
    return _openFee;
  }

  function _addOpenPosition(uint256 _tokenId) internal {
    _openPositionsIdx[_tokenId] = allOpenPositions.length;
    allOpenPositions.push(_tokenId);
  }

  function _removeOpenPosition(uint256 _tokenId) internal {
    uint256 _allPositionsIdx = _openPositionsIdx[_tokenId];
    uint256 _tokenIdMoving = allOpenPositions[allOpenPositions.length - 1];
    delete _openPositionsIdx[_tokenId];
    _openPositionsIdx[_tokenIdMoving] = _allPositionsIdx;
    allOpenPositions[_allPositionsIdx] = _tokenIdMoving;
    allOpenPositions.pop();
  }

  function _checkAndSettlePosition(
    uint256 _tokenId,
    address _closingUser,
    uint256 _returnAmount
  ) internal {
    Position storage _position = positions[_tokenId];
    if (_returnAmount > 0) {
      if (_position.collateralToken == mainCollateralToken) {
        _position.isSettled = true;
        ERC20(_position.collateralToken).safeTransfer(
          _closingUser,
          _returnAmount
        );
      } else {
        if (_returnAmount > _position.collateralAmount) {
          if (_position.collateralToken == address(0)) {
            uint256 _before = address(this).balance;
            payable(_closingUser).call{ value: _position.collateralAmount }('');
            require(
              address(this).balance >= _before - _position.collateralAmount,
              'NAT1'
            );
          } else {
            ERC20(_position.collateralToken).safeTransfer(
              _closingUser,
              _position.collateralAmount
            );
          }
          _position.collateralCloseUnsettled =
            _returnAmount -
            _position.collateralAmount;
          _unsettledPositionsIdx[_tokenId] = allUnsettledPositions.length;
          allUnsettledPositions.push(_tokenId);
          emit CloseUnsettledPosition(_tokenId);
        } else {
          _position.isSettled = true;
          if (_position.collateralToken == address(0)) {
            uint256 _before = address(this).balance;
            payable(_closingUser).call{ value: _returnAmount }('');
            require(address(this).balance >= _before - _returnAmount, 'NAT1');
          } else {
            ERC20(_position.collateralToken).safeTransfer(
              _closingUser,
              _returnAmount
            );
          }
        }
      }
    } else {
      _position.isSettled = true;
    }
  }

  function _getAndClosePositionPLInfo(uint256 _tokenId, address _closingUser)
    internal
  {
    Position storage _position = positions[_tokenId];
    (
      uint256 _closingFeePosition,
      uint256 _closingFeeDurationTotal
    ) = getPositionCloseFees(_tokenId);
    uint256 _totalCloseFees = _closingFeePosition + _closingFeeDurationTotal;

    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      uint256 _absolutePL,
      bool _isProfit,
      bool _canCloseInProfit
    ) = getIndexAndPLInfo(_tokenId);

    // adjust amount returned based on closing fees incurred then transfer to position holder
    _amountReturnToUser = _totalCloseFees > _amountReturnToUser
      ? 0
      : _amountReturnToUser - _totalCloseFees;
    _checkAndSettlePosition(_tokenId, _closingUser, _amountReturnToUser);

    _position.lifecycle.closeTime = block.timestamp;
    _position.lifecycle.closeFees = _totalCloseFees;
    _position.indexPriceSettle = _currentIndexPrice;
    _position.amountWon = _isProfit && _canCloseInProfit ? _absolutePL : 0;
    _position.amountLost = _isProfit
      ? 0
      : _absolutePL > _position.collateralAmount
      ? _position.collateralAmount
      : _absolutePL;
  }

  function _closeIndividualFeeds(uint256 _tokenId) internal {
    // update settle phase and round data for all proxies that make up the index
    for (uint256 _i = 0; _i < positions[_tokenId].feeds.length; _i++) {
      PositionIndexFeed storage _feed = positions[_tokenId].feeds[_i];
      (uint16 _phase, uint80 _round, ) = getLatestProxyInfo(_feed.feed.proxy);
      _feed.phaseIdSettle = _phase;
      _feed.roundIdSettle = _round;
    }
  }

  function _validateAndUpdateOpenAmounts(uint256 _tokenId, uint256 _amount)
    internal
  {
    if (positions[_tokenId].isLong) {
      amtOpenLong[positions[_tokenId].collateralToken] += _amount;
    } else {
      amtOpenShort[positions[_tokenId].collateralToken] += _amount;
    }
    if (maxCollateralOpenDiff[positions[_tokenId].collateralToken] > 0) {
      uint256 _openDiff = amtOpenLong[positions[_tokenId].collateralToken] >
        amtOpenShort[positions[_tokenId].collateralToken]
        ? amtOpenLong[positions[_tokenId].collateralToken] -
          amtOpenShort[positions[_tokenId].collateralToken]
        : amtOpenShort[positions[_tokenId].collateralToken] -
          amtOpenLong[positions[_tokenId].collateralToken];
      require(
        _openDiff <= maxCollateralOpenDiff[positions[_tokenId].collateralToken],
        'max collateral reached'
      );
    }
  }

  function _updateCloseAmounts(uint256 _tokenId) internal {
    if (positions[_tokenId].isLong) {
      amtOpenLong[positions[_tokenId].collateralToken] -= positions[_tokenId]
        .positionAmount;
    } else {
      amtOpenShort[positions[_tokenId].collateralToken] -= positions[_tokenId]
        .positionAmount;
    }
  }

  function shouldPositionLiquidate(uint256 _tokenId)
    public
    view
    returns (bool)
  {
    uint256 _priceChangeForLiquidation = getLiquidationPriceChange(_tokenId);
    (uint256 _closingFeeMain, uint256 _closingFeeTime) = getPositionCloseFees(
      _tokenId
    );
    (
      uint256 _currentIndexPrice,
      uint256 _amountReturnToUser,
      ,
      bool _isProfit,

    ) = getIndexAndPLInfo(_tokenId);
    uint256 _indexPriceDelinquencyPrice = positions[_tokenId].isLong
      ? positions[_tokenId].indexPriceStart - _priceChangeForLiquidation
      : positions[_tokenId].indexPriceStart + _priceChangeForLiquidation;
    bool _priceInLiquidation = positions[_tokenId].isLong
      ? _currentIndexPrice <= _indexPriceDelinquencyPrice
      : _currentIndexPrice >= _indexPriceDelinquencyPrice;
    bool _feesExceedReturn = !_isProfit &&
      _closingFeeMain + _closingFeeTime >= _amountReturnToUser;
    return _priceInLiquidation || _feesExceedReturn;
  }

  function shouldPositionCloseFromTrigger(uint256 _tokenId)
    public
    view
    returns (bool)
  {
    uint256 _currIdxPrice = getPositionIndexPrice(_tokenId);
    for (uint256 _i = 0; _i < positionTriggerOrders[_tokenId].length; _i++) {
      uint256 _target = positionTriggerOrders[_tokenId][_i].idxPriceTarget;
      bool _lessThanEQ = _target <
        positionTriggerOrders[_tokenId][_i].idxPriceCurrent;
      if (_lessThanEQ) {
        if (_currIdxPrice <= _target) {
          return true;
        }
      } else {
        if (_currIdxPrice >= _target) {
          return true;
        }
      }
    }
    return false;
  }
}
