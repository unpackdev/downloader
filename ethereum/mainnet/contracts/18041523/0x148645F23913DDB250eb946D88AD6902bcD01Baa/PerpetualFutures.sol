// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IFeeReducer.sol";
import "./IPerpetualFutures.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./pfYDF.sol";
import "./PerpsTriggerOrders.sol";
import "./PerpetualFuturesUnsettledHandler.sol";

contract PerpetualFutures is Ownable, PerpsTriggerOrders {
  using SafeERC20 for IERC20Metadata;

  uint256 constant FACTOR = 10**18;
  uint256 constant PERC_DEN = 100000;

  pfYDF public perpsNft;
  IFeeReducer public feeReducer;

  bool public tradingEnabled;

  mapping(address => bool) public relays;

  address public mainCollateralToken =
    0x30dcBa0405004cF124045793E1933C798Af9E66a;
  mapping(address => bool) _validColl;
  address[] _allCollTokens;
  mapping(address => uint256) _allCollTokensInd;

  uint16 public maxLeverage = 1500; // 150x
  // indexIdx => max leverage
  mapping(uint256 => uint16) public maxLevIdxOverride;

  uint256 public maxProfitPerc = PERC_DEN * 10; // 10x collateral amount
  uint256 public openFeeETH;
  uint256 public openFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closeFeePositionSize = (PERC_DEN * 1) / 1000; // 0.1%
  uint256 public closeFeePerDurationUnit = 1 hours;
  uint256 public closeFeePerDuration = (PERC_DEN * 5) / 100000; // 0.005% / hour

  // collateral token => amount
  mapping(address => uint256) public amtOpenLong;
  mapping(address => uint256) public amtOpenShort;
  mapping(address => uint256) public maxCollateralOpenDiff;
  mapping(address => uint256) public minCollateralAmount;

  IPerpetualFutures.Index[] public indexes;

  uint256 public pendingPositionExp = 10 minutes;
  IPerpetualFutures.ActionRequest[] public pendingOpenPositions;
  IPerpetualFutures.ActionRequest[] public pendingClosePositions; // tokenId[]
  mapping(uint256 => bool) _hasPendingCloseRequest;

  // tokenId => Position
  mapping(uint256 => IPerpetualFutures.Position) public positions;
  // tokenId[]
  uint256[] public allOpenPositions;
  // tokenId => allOpenPositions index
  mapping(uint256 => uint256) internal _openPositionsIdx;

  PerpetualFuturesUnsettledHandler public unsettledHandler;

  event CloseUnsettledPosition(uint256 indexed tokenId);
  event OpenPositionRequest(
    address indexed user,
    uint256 requestIdx,
    uint256 indexPriceStartDesired,
    uint256 positionCollateral,
    bool isLong,
    uint256 leverage
  );
  event OpenPosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 positionCollateral,
    bool isLong,
    uint256 leverage
  );
  event ClosePositionRequest(
    uint256 indexed tokenId,
    address indexed user,
    uint256 requestIdx,
    uint256 collateralReduction
  );
  event ClosePosition(
    uint256 indexed tokenId,
    address indexed user,
    uint256 indexPriceStart,
    uint256 indexPriceSettle,
    uint256 amountWon,
    uint256 amountLost
  );
  event LiquidatePosition(uint256 indexed tokenId);
  event ClosePositionFromTriggerOrder(uint256 indexed tokenId);
  event SettlePosition(address indexed to, uint256 amountSettled);

  modifier onlyRelay() {
    require(relays[_msgSender()], 'RELAY');
    _;
  }

  modifier onlyUnsettled() {
    require(_msgSender() == address(unsettledHandler), 'UNSETTLED');
    _;
  }

  constructor() {
    perpsNft = new pfYDF();
    perpsNft.transferOwnership(_msgSender());
    _setPfydf(address(perpsNft));

    unsettledHandler = new PerpetualFuturesUnsettledHandler();
  }

  function getAllIndexes()
    external
    view
    returns (IPerpetualFutures.Index[] memory)
  {
    return indexes;
  }

  function getAllValidCollateralTokens()
    external
    view
    returns (address[] memory)
  {
    return _allCollTokens;
  }

  function getAllOpenPositions() external view returns (uint256[] memory) {
    return allOpenPositions;
  }

  function getOpenPositionRequests()
    external
    view
    returns (IPerpetualFutures.ActionRequest[] memory)
  {
    return pendingOpenPositions;
  }

  function getClosePositionRequests()
    external
    view
    returns (IPerpetualFutures.ActionRequest[] memory)
  {
    return pendingClosePositions;
  }

  function openPositionRequest(
    address _collToken,
    uint256 _indexInd,
    uint256 _desiredPrice,
    uint256 _slippage, // 1 == 0.1%, 10 == 1%
    uint256 _collateral,
    uint16 _leverage, // 10 == 1x, 1000 == 100x
    bool _isLong,
    uint256 _tokenId, // optional: if adding margin
    address _owner // optional: if opening for another wallet
  ) external payable {
    require(tradingEnabled);
    require(indexes[_indexInd].isActive, 'INVIDX');
    require(_leverage >= 10);
    require(_collateral >= minCollateralAmount[_collToken], 'MINCOLL');
    require(_canOpenAgainstIndex(_indexInd, 0), 'INDOOB1');
    // TODO: include address(0) if we support ETH as collateral
    require(
      _collToken == mainCollateralToken || _validColl[_collToken],
      'POSTOKEN1'
    );
    if (maxLevIdxOverride[_indexInd] > 0) {
      require(_leverage <= maxLevIdxOverride[_indexInd], 'LEV1');
    } else {
      require(_leverage <= maxLeverage, 'LEV2');
    }
    if (openFeeETH > 0) {
      require(msg.value == openFeeETH, 'OPENFEE');
      (bool _s, ) = payable(owner()).call{ value: openFeeETH }('');
      require(_s, 'FEESEND');
    }
    if (_tokenId > 0) {
      require(perpsNft.ownerOf(_tokenId) == _msgSender(), 'OWNER');
    }

    pendingOpenPositions.push(
      IPerpetualFutures.ActionRequest({
        timestamp: block.timestamp,
        requester: _msgSender(),
        tokenId: _tokenId,
        indexIdx: _indexInd,
        owner: _owner == address(0) ? _msgSender() : _owner,
        collateralToken: _collToken,
        collateralAmount: _collateral,
        isLong: _isLong,
        leverage: _leverage,
        openSlippage: _slippage,
        desiredIdxPriceStart: _desiredPrice
      })
    );
    emit OpenPositionRequest(
      _msgSender(),
      pendingOpenPositions.length - 1,
      _desiredPrice,
      _collateral,
      _isLong,
      _leverage
    );
  }

  function openPositionRequestCancel(uint256 _openReqIdx) external {
    require(
      _msgSender() == pendingOpenPositions[_openReqIdx].requester ||
        block.timestamp >
        pendingOpenPositions[_openReqIdx].timestamp + pendingPositionExp
    );
    pendingOpenPositions[_openReqIdx] = pendingOpenPositions[
      pendingOpenPositions.length - 1
    ];
    pendingOpenPositions.pop();
  }

  function openPosition(uint256 _openPrice, uint256 _pendingIdx)
    external
    onlyRelay
  {
    IPerpetualFutures.ActionRequest memory _ar = pendingOpenPositions[
      _pendingIdx
    ];
    pendingOpenPositions[_pendingIdx] = pendingOpenPositions[
      pendingOpenPositions.length - 1
    ];
    pendingOpenPositions.pop();

    (uint256 _openFee, uint256 _finalColl) = _processCollateral(
      _ar.requester,
      _ar.tokenId == 0
        ? _ar.collateralToken
        : positions[_ar.tokenId].collateralToken,
      _ar.collateralAmount,
      _ar.leverage
    );

    _slippageValidation(
      _ar.desiredIdxPriceStart,
      _openPrice,
      _ar.openSlippage,
      _ar.isLong
    );

    uint256 _newTokenId = _ar.tokenId == 0
      ? perpsNft.mint(_ar.owner)
      : _ar.tokenId;
    uint256 _currentCollateral = positions[_newTokenId].collateralAmount;
    uint16 _currentLeverage = positions[_newTokenId].leverage;
    IPerpetualFutures.Position storage _pos = _setOpenPosition(
      _newTokenId,
      _openFee,
      _openPrice,
      _finalColl,
      _ar
    );
    _validateAndUpdateOpenAmounts(
      _newTokenId,
      _getPositionAmount(_currentCollateral, _currentLeverage),
      _getPositionAmount(_pos.collateralAmount, _pos.leverage)
    );
    emit OpenPosition(
      _newTokenId,
      _ar.owner,
      _openPrice,
      _finalColl,
      _pos.isLong,
      _pos.leverage
    );
  }

  function closePositionRequest(uint256 _tokenId, uint256 _collateralReduction)
    external
  {
    address _user = perpsNft.ownerOf(_tokenId);
    require(_msgSender() == _user);
    require(!_hasPendingCloseRequest[_tokenId]);
    _hasPendingCloseRequest[_tokenId] = true;
    pendingClosePositions.push(
      IPerpetualFutures.ActionRequest({
        timestamp: block.timestamp,
        requester: _msgSender(),
        tokenId: _tokenId,
        collateralAmount: _collateralReduction,
        // noops
        indexIdx: positions[_tokenId].indexIdx,
        owner: _msgSender(),
        collateralToken: address(0),
        isLong: false,
        leverage: 0,
        openSlippage: 0,
        desiredIdxPriceStart: 0
      })
    );
    emit ClosePositionRequest(
      _tokenId,
      _msgSender(),
      pendingClosePositions.length - 1,
      _collateralReduction
    );
  }

  function closePositionRequestCancel(uint256 _closeReqIdx) external {
    uint256 _tokenId = pendingClosePositions[_closeReqIdx].tokenId;
    if (
      block.timestamp <=
      pendingClosePositions[_closeReqIdx].timestamp + pendingPositionExp
    ) {
      address _user = perpsNft.ownerOf(_tokenId);
      require(_msgSender() == _user);
    }
    delete _hasPendingCloseRequest[_tokenId];
    pendingClosePositions[_closeReqIdx] = pendingClosePositions[
      pendingClosePositions.length - 1
    ];
    pendingClosePositions.pop();
  }

  function closePosition(uint256 _closePrice, uint256 _pendingCloseIdx)
    external
    onlyRelay
  {
    uint256 _tokenId = pendingClosePositions[_pendingCloseIdx].tokenId;
    require(_tokenId > 0);
    uint256 _collateralReduction = pendingClosePositions[_pendingCloseIdx]
      .collateralAmount;
    delete _hasPendingCloseRequest[_tokenId];
    pendingClosePositions[_pendingCloseIdx] = pendingClosePositions[
      pendingClosePositions.length - 1
    ];
    pendingClosePositions.pop();
    _closePosition(_tokenId, _closePrice, _collateralReduction);
  }

  function _closePosition(
    uint256 _tokenId,
    uint256 _currentPrice,
    uint256 _collateralReduction // 0 for closing completely
  ) internal {
    address _user = perpsNft.ownerOf(_tokenId);
    require(perpsNft.doesTokenExist(_tokenId));

    uint256 _prevCollateral = positions[_tokenId].collateralAmount;
    uint16 _prevLeverage = positions[_tokenId].leverage;
    bool _isClosed = _getAndClosePositionPLInfo(
      _tokenId,
      _user,
      _currentPrice,
      _collateralReduction
    );
    if (_isClosed) {
      _updateCloseAmounts(
        _tokenId,
        _getPositionAmount(_prevCollateral, _prevLeverage),
        0
      );
      _removeOpenPosition(_tokenId);
      perpsNft.burn(_tokenId);
      emit ClosePosition(
        _tokenId,
        _user,
        positions[_tokenId].indexPriceStart,
        positions[_tokenId].indexPriceSettle,
        positions[_tokenId].amountWon,
        positions[_tokenId].amountLost
      );
    } else {
      _updateCloseAmounts(
        _tokenId,
        _getPositionAmount(_prevCollateral, _prevLeverage),
        _getPositionAmount(
          positions[_tokenId].collateralAmount,
          positions[_tokenId].leverage
        )
      );
    }
  }

  function executeSettlement(
    uint256 tokenId,
    address _to,
    uint256 _amount
  ) external onlyUnsettled {
    positions[tokenId].mainCollateralSettledAmount = _amount;
    IERC20Metadata(mainCollateralToken).safeTransfer(_to, _amount);
    emit SettlePosition(_to, _amount);
  }

  function getIndexAndPLInfo(uint256 _tokenId, uint256 _currentIndexPrice)
    external
    view
    returns (
      uint256,
      uint256,
      bool,
      bool
    )
  {
    IPerpetualFutures.Position memory _position = positions[_tokenId];
    return
      _getIdxAndPLInfo(
        _position.indexPriceStart,
        _currentIndexPrice,
        _position.collateralAmount,
        _position.leverage,
        _position.isLong
      );
  }

  function _getIdxAndPLInfo(
    uint256 _openIndexPrice,
    uint256 _currentIndexPrice,
    uint256 _collateralAmount,
    uint16 _leverage,
    bool _isLong
  )
    internal
    view
    returns (
      uint256,
      uint256,
      bool,
      bool
    )
  {
    bool _settlePriceIsHigher = _currentIndexPrice > _openIndexPrice;
    uint256 _indexAbsDiffFromOpen = _settlePriceIsHigher
      ? _currentIndexPrice - _openIndexPrice
      : _openIndexPrice - _currentIndexPrice;
    uint256 _absolutePL = (_getPositionAmount(_collateralAmount, _leverage) *
      _indexAbsDiffFromOpen) / _openIndexPrice;
    bool _isProfit = _isLong ? _settlePriceIsHigher : !_settlePriceIsHigher;

    bool _isMax;
    if (_isProfit) {
      uint256 _maxProfit = (_collateralAmount * maxProfitPerc) / PERC_DEN;
      if (_absolutePL > _maxProfit) {
        _absolutePL = _maxProfit;
        _isMax = true;
      }
    }

    uint256 _amountReturnToUser = _collateralAmount;
    if (_isProfit) {
      _amountReturnToUser += _absolutePL;
    } else {
      if (_absolutePL > _amountReturnToUser) {
        _amountReturnToUser = 0;
      } else {
        _amountReturnToUser -= _absolutePL;
      }
    }
    return (_amountReturnToUser, _absolutePL, _isProfit, _isMax);
  }

  function getLiquidationPriceChange(uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    // 85% of exact liquidation as buffer
    // NOTE: _position.leverage == 10 means 1x
    // Ex. price start == 100, leverage == 15 (1.5x)
    // (priceStart / (15 / 10)) * (8.5 / 10)
    // (priceStart * 10 / 15) * (8.5 / 10)
    // (priceStart / 15) * 8.5
    // (priceStart * 8.5) / 15
    return
      (positions[_tokenId].indexPriceStart * 85) /
      10 /
      positions[_tokenId].leverage;
  }

  function getPositionCloseFees(uint256 _tokenId)
    external
    view
    returns (uint256, uint256)
  {
    return
      _getCloseFees(
        _tokenId,
        positions[_tokenId].collateralToken,
        positions[_tokenId].collateralAmount,
        positions[_tokenId].leverage,
        positions[_tokenId].lifecycle.openTime
      );
  }

  function _getCloseFees(
    uint256 _tokenId,
    address _collateral,
    uint256 _amount,
    uint16 _leverage,
    uint256 _openTime
  ) internal view returns (uint256, uint256) {
    address _owner = perpsNft.ownerOf(_tokenId);
    (uint256 _percentOff, uint256 _percOffDenomenator) = getFeeDiscount(
      _owner,
      _collateral,
      _amount,
      _leverage
    );
    uint256 _positionAmount = _getPositionAmount(_amount, _leverage);
    uint256 _closingFeePosition = (_positionAmount * closeFeePositionSize) /
      PERC_DEN;
    uint256 _closingFeeDurationPerUnit = (_positionAmount *
      closeFeePerDuration) / PERC_DEN;
    uint256 _closingFeeDurationTotal = (_closingFeeDurationPerUnit *
      (block.timestamp - _openTime)) / closeFeePerDurationUnit;

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

  function setValidCollateralToken(address _token, bool _isValid)
    external
    onlyOwner
  {
    require(_validColl[_token] != _isValid);
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

  // 10 == 1x, 1000 == 100x, etc.
  function setMaxLeverage(uint16 _max) external onlyOwner {
    require(_max <= 2500);
    maxLeverage = _max;
  }

  function setMaxLevIdxOverride(uint256 _idx, uint16 _max) external onlyOwner {
    require(_max <= 2500);
    maxLevIdxOverride[_idx] = _max;
  }

  function setMaxProfitPerc(uint256 _max) external onlyOwner {
    require(_max >= PERC_DEN);
    maxProfitPerc = _max;
  }

  function setMaxTriggerOrders(uint8 _max) external onlyOwner {
    maxTriggerOrders = _max;
  }

  function setOpenFeePositionSize(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 10) / 100);
    openFeePositionSize = _percentage;
  }

  function setOpenFeeETH(uint256 _wei) external onlyOwner {
    openFeeETH = _wei;
  }

  function setCloseFeePositionSize(uint256 _percentage) external onlyOwner {
    require(_percentage < (PERC_DEN * 10) / 100);
    closeFeePositionSize = _percentage;
  }

  function setPendingPositionExp(uint256 _expiration) external onlyOwner {
    require(_expiration <= 1 hours);
    pendingPositionExp = _expiration;
  }

  function setCloseFeePositionPerDurationUnit(uint256 _seconds)
    external
    onlyOwner
  {
    require(_seconds >= 10 minutes);
    closeFeePerDurationUnit = _seconds;
  }

  function setClosePositionFeePerDuration(uint256 _percentage)
    external
    onlyOwner
  {
    require(_percentage < (PERC_DEN * 1) / 100);
    closeFeePerDuration = _percentage;
  }

  function setRelay(address _wallet, bool _isRelay) external onlyOwner {
    require(relays[_wallet] != _isRelay);
    relays[_wallet] = _isRelay;
  }

  function setMaxCollateralOpenDiff(address _collateral, uint256 _amount)
    external
    onlyOwner
  {
    maxCollateralOpenDiff[_collateral] = _amount;
  }

  function setMinCollateralAmount(address _collateral, uint256 _amount)
    external
    onlyOwner
  {
    minCollateralAmount[_collateral] = _amount;
  }

  function addIndex(string memory _name) external onlyOwner {
    IPerpetualFutures.Index storage _newIndex = indexes.push();
    _newIndex.name = _name;
    _newIndex.isActive = true;
  }

  function activateIndex(uint256 _idx) external onlyOwner {
    require(_idx < indexes.length);
    indexes[_idx].isActive = true;
  }

  function removeIndex(uint256 _idx) external onlyOwner {
    indexes[_idx].isActive = false;
  }

  function updateIndexOpenTimeBounds(
    uint256 _indexInd,
    uint256 _dowOpenMin,
    uint256 _dowOpenMax,
    uint256 _hourOpenMin,
    uint256 _hourOpenMax
  ) external onlyOwner {
    IPerpetualFutures.Index storage _index = indexes[_indexInd];
    _index.dowOpenMin = _dowOpenMin;
    _index.dowOpenMax = _dowOpenMax;
    _index.hourOpenMin = _hourOpenMin;
    _index.hourOpenMax = _hourOpenMax;
  }

  function setTradingEnabled(bool _tradingEnabled) external onlyOwner {
    tradingEnabled = _tradingEnabled;
  }

  function setFeeReducer(IFeeReducer _reducer) external onlyOwner {
    feeReducer = _reducer;
  }

  function processFees(uint256 _amount) external onlyOwner {
    IERC20Metadata(mainCollateralToken).safeTransfer(
      mainCollateralToken,
      _amount
    );
  }

  function checkUpkeep(uint256 _tokenId, uint256 _currentPrice)
    external
    view
    returns (bool upkeepNeeded)
  {
    (bool _shouldTrigger, ) = shouldPositionCloseFromTrigger(
      _tokenId,
      _currentPrice
    );
    return shouldPositionLiquidate(_tokenId, _currentPrice) || _shouldTrigger;
  }

  function performUpkeep(uint256 _tokenId, uint256 _currentPrice)
    external
    onlyRelay
    returns (bool wasLiquidated)
  {
    return _checkAndLiquidatePosition(_tokenId, _currentPrice);
  }

  function _checkAndLiquidatePosition(uint256 _tokenId, uint256 _currentPrice)
    internal
    returns (bool)
  {
    bool _shouldLiquidate = shouldPositionLiquidate(_tokenId, _currentPrice);
    (
      bool _triggerClose,
      uint256 _collateralChange
    ) = shouldPositionCloseFromTrigger(_tokenId, _currentPrice);
    if (_shouldLiquidate || _triggerClose) {
      _closePosition(_tokenId, _currentPrice, _collateralChange);

      if (_shouldLiquidate) {
        emit LiquidatePosition(_tokenId);
      } else if (_triggerClose) {
        emit ClosePositionFromTriggerOrder(_tokenId);
      }
      return true;
    }
    return false;
  }

  function getFeeDiscount(
    address _wallet,
    address _token,
    uint256 _amount,
    uint16 _leverage
  ) public view returns (uint256, uint256) {
    return
      address(feeReducer) != address(0)
        ? feeReducer.percentDiscount(_wallet, _token, _amount, _leverage)
        : (0, 0);
  }

  function _getPositionOpenFee(
    address _user,
    address _collateralToken,
    uint256 _collateral,
    uint16 _leverage
  ) internal view returns (uint256) {
    uint256 _positionPreFee = (_collateral * _leverage) / 10;
    uint256 _openFee = (_positionPreFee * openFeePositionSize) / PERC_DEN;
    (uint256 _percentOff, uint256 _percOffDenomenator) = getFeeDiscount(
      _user,
      _collateralToken,
      _collateral,
      _leverage
    );
    // user has discount from fees
    if (_percentOff > 0) {
      _openFee -= (_openFee * _percentOff) / _percOffDenomenator;
    }
    return _openFee;
  }

  function _setOpenPosition(
    uint256 _tokenId,
    uint256 _openFee,
    uint256 _openPrice,
    uint256 _newCollateral,
    IPerpetualFutures.ActionRequest memory _ar
  ) internal returns (IPerpetualFutures.Position storage) {
    IPerpetualFutures.Position storage _pos = positions[_tokenId];

    if (_tokenId == _ar.tokenId) {
      // add margin to existing position
      uint256 _prevSize = _getPositionAmount(
        _pos.collateralAmount,
        _pos.leverage
      );
      uint256 _addedSize = _getPositionAmount(_newCollateral, _ar.leverage);
      uint256 _newSize = _prevSize + _addedSize;
      (, uint256 _closingFeeDurationTotal) = _getCloseFees(
        _tokenId,
        _pos.collateralToken,
        _pos.collateralAmount,
        _pos.leverage,
        _pos.lifecycle.openTime
      );
      _pos.leverage = uint16(
        (_newSize * 10) / (_pos.collateralAmount + _newCollateral)
      );
      _pos.indexPriceStart =
        ((_pos.indexPriceStart * _prevSize) + (_openPrice * _addedSize)) /
        _newSize;
      _pos.lifecycle.closeFees += _closingFeeDurationTotal;
    } else {
      // new position
      _pos.indexIdx = _ar.indexIdx;
      _pos.collateralToken = _ar.collateralToken;
      _pos.isLong = _ar.isLong;
      _pos.leverage = _ar.leverage;
      _pos.indexPriceStart = _openPrice;
      _openPositionsIdx[_tokenId] = allOpenPositions.length;
      allOpenPositions.push(_tokenId);
    }
    _pos.collateralAmount += _newCollateral;
    _pos.lifecycle.openFees += _openFee;
    _pos.lifecycle.openTime = block.timestamp; // reset since we already added to closeFees
    return _pos;
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
    address _collateralToken,
    uint256 _collateralAmount,
    address _closingUser,
    uint256 _returnAmount,
    bool _isClosing
  ) internal {
    if (_returnAmount > 0) {
      if (_collateralToken == mainCollateralToken) {
        positions[_tokenId].isSettled = _isClosing;
        IERC20Metadata(_collateralToken).safeTransfer(
          _closingUser,
          _returnAmount
        );
      } else {
        if (_returnAmount > _collateralAmount) {
          if (_collateralToken == address(0)) {
            uint256 _before = address(this).balance;
            payable(_closingUser).call{ value: _collateralAmount }('');
            require(address(this).balance >= _before - _collateralAmount);
          } else {
            IERC20Metadata(_collateralToken).safeTransfer(
              _closingUser,
              _collateralAmount
            );
          }
          unsettledHandler.addUnsettledPosition(
            _tokenId,
            _closingUser,
            _collateralToken,
            _returnAmount - _collateralAmount
          );
          emit CloseUnsettledPosition(_tokenId);
        } else {
          positions[_tokenId].isSettled = _isClosing;
          if (_collateralToken == address(0)) {
            uint256 _before = address(this).balance;
            payable(_closingUser).call{ value: _returnAmount }('');
            require(address(this).balance >= _before - _returnAmount);
          } else {
            IERC20Metadata(_collateralToken).safeTransfer(
              _closingUser,
              _returnAmount
            );
          }
        }
      }
    } else {
      positions[_tokenId].isSettled = _isClosing;
    }
  }

  function _getPositionAmount(uint256 _collateralAmount, uint16 _leverage)
    internal
    pure
    returns (uint256)
  {
    return (_collateralAmount * _leverage) / 10;
  }

  function _getAndClosePositionPLInfo(
    uint256 _tokenId,
    address _closingUser,
    uint256 _currentPrice,
    uint256 _collateralReduction
  ) internal returns (bool) {
    IPerpetualFutures.Position storage _position = positions[_tokenId];
    bool _isClosing = _collateralReduction == 0 ||
      _collateralReduction >= _position.collateralAmount;
    (
      uint256 _closingFeePosition,
      uint256 _closingFeeDurationTotal
    ) = _getCloseFees(
        _tokenId,
        _position.collateralToken,
        _isClosing ? _position.collateralAmount : _collateralReduction,
        _position.leverage,
        _position.lifecycle.openTime
      );
    uint256 _totalCloseFees = _position.lifecycle.closeFees +
      _closingFeePosition +
      _closingFeeDurationTotal;

    _position.lifecycle.closeFees += _totalCloseFees;

    (
      uint256 _amountReturnToUser,
      uint256 _absolutePL,
      bool _isProfit,

    ) = _getIdxAndPLInfo(
        _position.indexPriceStart,
        _currentPrice,
        _isClosing ? _position.collateralAmount : _collateralReduction,
        _position.leverage,
        _position.isLong
      );

    _position.amountWon += _isProfit ? _absolutePL : 0;
    _position.amountLost += _isProfit
      ? 0
      : _absolutePL > _position.collateralAmount
      ? _position.collateralAmount
      : _absolutePL;

    if (_isClosing) {
      // closing position completely
      _position.lifecycle.closeTime = block.timestamp;
      _position.indexPriceSettle = _currentPrice;
      // adjust amount returned based on closing fees incurred
      _amountReturnToUser = _totalCloseFees > _amountReturnToUser
        ? 0
        : _amountReturnToUser - _totalCloseFees;
    } else {
      _position.collateralAmount -= _collateralReduction;
    }

    _checkAndSettlePosition(
      _tokenId,
      _position.collateralToken,
      _isClosing ? _position.collateralAmount : _collateralReduction,
      _closingUser,
      _amountReturnToUser,
      _isClosing
    );
    return _isClosing;
  }

  function _validateAndUpdateOpenAmounts(
    uint256 _tokenId,
    uint256 _oldPositionSize,
    uint256 _newPositionSize
  ) internal {
    if (positions[_tokenId].isLong) {
      amtOpenLong[positions[_tokenId].collateralToken] -= _oldPositionSize;
      amtOpenLong[positions[_tokenId].collateralToken] += _newPositionSize;
    } else {
      amtOpenShort[positions[_tokenId].collateralToken] -= _oldPositionSize;
      amtOpenShort[positions[_tokenId].collateralToken] += _newPositionSize;
    }
    if (maxCollateralOpenDiff[positions[_tokenId].collateralToken] > 0) {
      uint256 _openDiff = amtOpenLong[positions[_tokenId].collateralToken] >
        amtOpenShort[positions[_tokenId].collateralToken]
        ? amtOpenLong[positions[_tokenId].collateralToken] -
          amtOpenShort[positions[_tokenId].collateralToken]
        : amtOpenShort[positions[_tokenId].collateralToken] -
          amtOpenLong[positions[_tokenId].collateralToken];
      require(
        _openDiff <= maxCollateralOpenDiff[positions[_tokenId].collateralToken]
      );
    }
  }

  function _updateCloseAmounts(
    uint256 _tokenId,
    uint256 _previousPositionSize,
    uint256 _currentPositionSize
  ) internal {
    if (positions[_tokenId].isLong) {
      amtOpenLong[positions[_tokenId].collateralToken] -= _previousPositionSize;
      amtOpenLong[positions[_tokenId].collateralToken] += _currentPositionSize;
    } else {
      amtOpenShort[
        positions[_tokenId].collateralToken
      ] -= _previousPositionSize;
      amtOpenShort[positions[_tokenId].collateralToken] += _currentPositionSize;
    }
  }

  function _processCollateral(
    address _user,
    address _collToken,
    uint256 _collateral,
    uint16 _leverage
  ) internal returns (uint256, uint256) {
    uint256 _openFee;
    uint256 _finalCollateral;

    // native token
    if (_collToken == address(0)) {
      require(msg.value > 0, 'COLL3');
      _collateral = msg.value;
      _openFee = _getPositionOpenFee(_user, _collToken, _collateral, _leverage);
      _finalCollateral = _collateral - _openFee;
    } else {
      IERC20Metadata _collCont = IERC20Metadata(_collToken);
      require(_collCont.balanceOf(_user) >= _collateral, 'BAL1');

      uint256 _before = _collCont.balanceOf(address(this));
      _collCont.safeTransferFrom(_user, address(this), _collateral);
      _collateral = _collCont.balanceOf(address(this)) - _before;
      _openFee = _getPositionOpenFee(_user, _collToken, _collateral, _leverage);
      _finalCollateral = _collateral - _openFee;
    }
    return (_openFee, _finalCollateral);
  }

  function _slippageValidation(
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
        (_idxSlipDiff * FACTOR) / _desiredPrice <= (_slippage * FACTOR) / 1000
      );
    }
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
      uint256 _dow = BokkyPooBahsDateTimeLibrary.getDayOfWeek(_timestamp);
      if (_dow < _dowOpenMin || _dow > _dowOpenMax) {
        return false;
      }
    }
    if (_hourOpenMin >= 1 || _hourOpenMax >= 1) {
      uint256 _hour = BokkyPooBahsDateTimeLibrary.getHour(_timestamp);
      if (_hour < _hourOpenMin || _hour > _hourOpenMax) {
        return false;
      }
    }
    return true;
  }

  function shouldPositionLiquidate(uint256 _tokenId, uint256 _currentPrice)
    public
    view
    returns (bool)
  {
    IPerpetualFutures.Position memory _pos = positions[_tokenId];
    uint256 _priceChangeForLiquidation = getLiquidationPriceChange(_tokenId);
    (uint256 _closingFeeMain, uint256 _closingFeeTime) = _getCloseFees(
      _tokenId,
      _pos.collateralToken,
      _pos.collateralAmount,
      _pos.leverage,
      _pos.lifecycle.openTime
    );
    (uint256 _amountReturnToUser, , , bool _isMax) = _getIdxAndPLInfo(
      _pos.indexPriceStart,
      _currentPrice,
      _pos.collateralAmount,
      _pos.leverage,
      _pos.isLong
    );
    uint256 _indexPriceDelinquencyPrice = _pos.isLong
      ? _pos.indexPriceStart - _priceChangeForLiquidation
      : _pos.indexPriceStart + _priceChangeForLiquidation;
    bool _priceInLiquidation = _pos.isLong
      ? _currentPrice <= _indexPriceDelinquencyPrice
      : _currentPrice >= _indexPriceDelinquencyPrice;
    bool _feesExceedReturn = _closingFeeMain + _closingFeeTime >=
      _amountReturnToUser;
    return _priceInLiquidation || _feesExceedReturn || _isMax;
  }

  function shouldPositionCloseFromTrigger(
    uint256 _tokenId,
    uint256 _currIdxPrice
  ) public view returns (bool, uint256) {
    for (uint256 _i = 0; _i < triggerOrders[_tokenId].length; _i++) {
      uint256 _collateralChange = triggerOrders[_tokenId][_i]
        .amountCollateralChange;
      uint256 _target = triggerOrders[_tokenId][_i].idxPriceTarget;
      bool _lessThanEQ = _target < triggerOrders[_tokenId][_i].idxPriceCurrent;
      if (_lessThanEQ) {
        if (_currIdxPrice <= _target) {
          return (true, _collateralChange);
        }
      } else {
        if (_currIdxPrice >= _target) {
          return (true, _collateralChange);
        }
      }
    }
    return (false, 0);
  }

  function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
    IERC20Metadata _contract = IERC20Metadata(_token);
    _amount = _amount == 0 ? _contract.balanceOf(address(this)) : _amount;
    require(_amount > 0);
    _contract.safeTransfer(owner(), _amount);
  }

  function withdrawETH(uint256 _amount) external onlyOwner {
    _amount = _amount == 0 ? address(this).balance : _amount;
    (bool _s, ) = payable(owner()).call{ value: _amount }('');
    require(_s);
  }
}
