// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IPerpetualFutures.sol";

contract PerpetualFuturesLimitOrders is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IPerpetualFutures public perps;
  bool public enabled = true;
  uint256 public openServiceFee = 2 ether / 1000; // 0.002 ETH

  struct LimitOrder {
    bytes32 uid;
    uint256 openFeePaid;
    IPerpetualFutures.ActionRequest positionInfo;
  }

  mapping(bytes32 => address) _openOrderUIDs;
  LimitOrder[] public openOrders;

  event CreateLimitOrder(
    address indexed requestor,
    address indexed owner,
    address collateralToken,
    uint256 collateralAmount,
    uint256 indexIdx,
    uint256 desiredPrice,
    uint16 leverage,
    bool isLong
  );
  event CancelLimitOrder(
    address indexed owner,
    address collateralToken,
    uint256 collateralAmount,
    uint256 indexIdx,
    uint256 desiredPrice,
    uint16 leverage,
    bool isLong
  );
  event ProcessLimitOrder(
    address indexed owner,
    address collateralToken,
    uint256 collateralAmount,
    uint256 indexIdx,
    uint256 executedPrice,
    uint16 leverage,
    bool isLong
  );

  modifier onlyRelay() {
    require(perps.relays(msg.sender), 'RELAY: unauthorized');
    _;
  }

  constructor(IPerpetualFutures _perps) {
    perps = _perps;
  }

  function getOpenOrdersLength() external view returns (uint256) {
    return openOrders.length;
  }

  function getAllOpenOrders() external view returns (LimitOrder[] memory) {
    return openOrders;
  }

  function createOrder(
    address _positionUser,
    address _collToken,
    uint256 _indexIdx,
    uint256 _desiredPrice,
    uint256 _collateral,
    uint16 _leverage,
    bool _isLong
  ) external payable nonReentrant {
    require(enabled, 'CREATE: enabled');
    uint256 _posOpenFee = perps.openFeeETH();
    require(msg.value == openServiceFee + _posOpenFee, 'CREATE: fee');
    if (openServiceFee > 0) {
      (bool _s, ) = payable(owner()).call{ value: openServiceFee }('');
      require(_s, 'FEESEND');
    }
    _positionUser = _positionUser == address(0) ? _msgSender() : _positionUser;

    IERC20(_collToken).safeTransferFrom(
      _msgSender(),
      address(this),
      _collateral
    );

    bytes32 _uid = _getOrderUID(
      _msgSender(),
      _collToken,
      _collateral,
      _indexIdx,
      _desiredPrice,
      _leverage,
      _isLong
    );
    require(_openOrderUIDs[_uid] == address(0), 'DUPORDER');
    _openOrderUIDs[_uid] = _positionUser;
    openOrders.push(
      LimitOrder({
        uid: _uid,
        openFeePaid: _posOpenFee,
        positionInfo: IPerpetualFutures.ActionRequest({
          timestamp: block.timestamp,
          requester: _msgSender(),
          indexIdx: _indexIdx,
          tokenId: 0,
          owner: _positionUser,
          collateralToken: _collToken,
          collateralAmount: _collateral,
          isLong: _isLong,
          leverage: _leverage,
          openSlippage: 50,
          desiredIdxPriceStart: _desiredPrice
        })
      })
    );

    emit CreateLimitOrder(
      _msgSender(),
      _positionUser,
      _collToken,
      _collateral,
      _indexIdx,
      _desiredPrice,
      _leverage,
      _isLong
    );
  }

  function removeOrder(uint256 _idx) external nonReentrant {
    LimitOrder memory _order = openOrders[_idx];
    require(
      _msgSender() == _order.positionInfo.owner || _msgSender() == owner(),
      'REMOVE: auth'
    );
    if (_order.openFeePaid > 0) {
      (bool _s, ) = payable(_order.positionInfo.owner).call{
        value: _order.openFeePaid
      }('');
      require(_s, 'FEEREFUND');
    }
    bytes32 _uid = _getOrderUID(
      _order.positionInfo.owner,
      _order.positionInfo.collateralToken,
      _order.positionInfo.collateralAmount,
      _order.positionInfo.indexIdx,
      _order.positionInfo.desiredIdxPriceStart,
      _order.positionInfo.leverage,
      _order.positionInfo.isLong
    );
    delete _openOrderUIDs[_uid];
    IERC20(_order.positionInfo.collateralToken).safeTransfer(
      _order.positionInfo.owner,
      _order.positionInfo.collateralAmount
    );
    _removeOpenOrder(_idx);

    emit CancelLimitOrder(
      _order.positionInfo.owner,
      _order.positionInfo.collateralToken,
      _order.positionInfo.collateralAmount,
      _order.positionInfo.indexIdx,
      _order.positionInfo.desiredIdxPriceStart,
      _order.positionInfo.leverage,
      _order.positionInfo.isLong
    );
  }

  function _removeOpenOrder(uint256 _idx) internal {
    openOrders[_idx] = openOrders[openOrders.length - 1];
    openOrders.pop();
  }

  function _processOpenOrder(uint256 _idx, uint256 _currentPrice) internal {
    LimitOrder memory _order = openOrders[_idx];
    bool _shouldOpen = _shouldOpenOrder(_idx, _currentPrice);
    if (!_shouldOpen) {
      return;
    }

    IERC20(_order.positionInfo.collateralToken).safeApprove(
      address(perps),
      _order.positionInfo.collateralAmount
    );
    perps.openPositionRequest{ value: perps.openFeeETH() }(
      _order.positionInfo.collateralToken,
      _order.positionInfo.indexIdx,
      _currentPrice,
      _order.positionInfo.openSlippage,
      _order.positionInfo.collateralAmount,
      _order.positionInfo.leverage,
      _order.positionInfo.isLong,
      0,
      _order.positionInfo.owner
    );

    _removeOpenOrder(_idx);

    emit ProcessLimitOrder(
      _order.positionInfo.owner,
      _order.positionInfo.collateralToken,
      _order.positionInfo.collateralAmount,
      _order.positionInfo.indexIdx,
      _currentPrice,
      _order.positionInfo.leverage,
      _order.positionInfo.isLong
    );
  }

  function _shouldOpenOrder(uint256 _openOrderIdx, uint256 _currentPrice)
    internal
    view
    returns (bool)
  {
    LimitOrder memory _order = openOrders[_openOrderIdx];
    if (_order.positionInfo.isLong) {
      if (_currentPrice > _order.positionInfo.desiredIdxPriceStart) {
        return false;
      }
    } else {
      if (_currentPrice < _order.positionInfo.desiredIdxPriceStart) {
        return false;
      }
    }
    return true;
  }

  function _getOrderUID(
    address _owner,
    address _collateralToken,
    uint256 _collateralAmount,
    uint256 _indexIdx,
    uint256 _indexMarkPrice,
    uint16 _leverage,
    bool _isLong
  ) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          _owner,
          _collateralToken,
          _collateralAmount,
          _indexIdx,
          _indexMarkPrice,
          _leverage,
          _isLong
        )
      );
  }

  function checkUpkeep(uint256 _openOrderIdx, uint256 _currentPrice)
    external
    view
    returns (bool upkeepNeeded)
  {
    if (!enabled) {
      return false;
    }
    return _shouldOpenOrder(_openOrderIdx, _currentPrice);
  }

  function performUpkeep(uint256 _openOrderIdx, uint256 _currentPrice)
    external
    onlyRelay
  {
    require(enabled, 'ENABLED');
    if (!_shouldOpenOrder(_openOrderIdx, _currentPrice)) {
      return;
    }
    _processOpenOrder(_openOrderIdx, _currentPrice);
  }

  function setEnabled(bool _isEnabled) external onlyOwner {
    require(enabled != _isEnabled, 'ENABLE: toggle');
    enabled = _isEnabled;
  }

  function setOpenServiceFee(uint256 _wei) external onlyOwner {
    openServiceFee = _wei;
  }

  function withdrawERC20(IERC20 _token, uint256 _amount) external onlyOwner {
    _amount = _amount == 0 ? _token.balanceOf(address(this)) : _amount;
    _token.safeTransfer(owner(), _amount);
  }

  function withdrawETH(uint256 _amount) external onlyOwner {
    _amount = _amount == 0 ? address(this).balance : _amount;
    (bool _sent, ) = payable(owner()).call{ value: _amount }('');
    require(_sent, 'WITHDRAW');
  }
}
