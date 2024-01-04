// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./StoreInterface.sol";
import "./OracleAncillaryInterface.sol";
import "./FinderInterface.sol";
import "./IdentifierWhitelistInterface.sol";
import "./OptimisticOracleInterface.sol";
import "./Constants.sol";

import "./Testable.sol";
import "./Lockable.sol";
import "./FixedPoint.sol";
import "./AddressWhitelist.sol";

interface OptimisticRequester {
  function priceProposed(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external;

  function priceDisputed(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 refund
  ) external;

  function priceSettled(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 price
  ) external;
}

contract OptimisticOracle is OptimisticOracleInterface, Testable, Lockable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address;

  event RequestPrice(
    address indexed requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData,
    address currency,
    uint256 reward,
    uint256 finalFee
  );
  event ProposePrice(
    address indexed requester,
    address indexed proposer,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData,
    int256 proposedPrice
  );
  event DisputePrice(
    address indexed requester,
    address indexed proposer,
    address indexed disputer,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData
  );
  event Settle(
    address indexed requester,
    address indexed proposer,
    address indexed disputer,
    bytes32 identifier,
    uint256 timestamp,
    bytes ancillaryData,
    int256 price,
    uint256 payout
  );

  mapping(bytes32 => Request) public requests;

  FinderInterface public finder;

  uint256 public defaultLiveness;

  constructor(
    uint256 _liveness,
    address _finderAddress,
    address _timerAddress
  ) public Testable(_timerAddress) {
    finder = FinderInterface(_finderAddress);
    _validateLiveness(_liveness);
    defaultLiveness = _liveness;
  }

  function requestPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward
  ) external override nonReentrant() returns (uint256 totalBond) {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Invalid,
      'requestPrice: Invalid'
    );
    require(
      _getIdentifierWhitelist().isIdentifierSupported(identifier),
      'Unsupported identifier'
    );
    require(
      _getCollateralWhitelist().isOnWhitelist(address(currency)),
      'Unsupported currency'
    );
    require(timestamp <= getCurrentTime(), 'Timestamp in future');
    require(
      ancillaryData.length <= ancillaryBytesLimit,
      'Invalid ancillary data'
    );
    uint256 finalFee = _getStore().computeFinalFee(address(currency)).rawValue;
    requests[
      _getId(msg.sender, identifier, timestamp, ancillaryData)
    ] = Request({
      proposer: address(0),
      disputer: address(0),
      currency: currency,
      settled: false,
      refundOnDispute: false,
      proposedPrice: 0,
      resolvedPrice: 0,
      expirationTime: 0,
      reward: reward,
      finalFee: finalFee,
      bond: finalFee,
      customLiveness: 0
    });

    if (reward > 0) {
      currency.safeTransferFrom(msg.sender, address(this), reward);
    }

    emit RequestPrice(
      msg.sender,
      identifier,
      timestamp,
      ancillaryData,
      address(currency),
      reward,
      finalFee
    );

    return finalFee.mul(2);
  }

  function setBond(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 bond
  ) external override nonReentrant() returns (uint256 totalBond) {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'setBond: Requested'
    );
    Request storage request =
      _getRequest(msg.sender, identifier, timestamp, ancillaryData);
    request.bond = bond;

    return bond.add(request.finalFee);
  }

  function setRefundOnDispute(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override nonReentrant() {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'setRefundOnDispute: Requested'
    );
    _getRequest(msg.sender, identifier, timestamp, ancillaryData)
      .refundOnDispute = true;
  }

  function setCustomLiveness(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 customLiveness
  ) external override nonReentrant() {
    require(
      getState(msg.sender, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'setCustomLiveness: Requested'
    );
    _validateLiveness(customLiveness);
    _getRequest(msg.sender, identifier, timestamp, ancillaryData)
      .customLiveness = customLiveness;
  }

  function proposePriceFor(
    address proposer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) public override nonReentrant() returns (uint256 totalBond) {
    require(proposer != address(0), 'proposer address must be non 0');
    require(
      getState(requester, identifier, timestamp, ancillaryData) ==
        State.Requested,
      'proposePriceFor: Requested'
    );
    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);
    request.proposer = proposer;
    request.proposedPrice = proposedPrice;

    request.expirationTime = getCurrentTime().add(
      request.customLiveness != 0 ? request.customLiveness : defaultLiveness
    );

    totalBond = request.bond.add(request.finalFee);
    if (totalBond > 0) {
      request.currency.safeTransferFrom(msg.sender, address(this), totalBond);
    }

    emit ProposePrice(
      requester,
      proposer,
      identifier,
      timestamp,
      ancillaryData,
      proposedPrice
    );

    if (address(requester).isContract())
      try
        OptimisticRequester(requester).priceProposed(
          identifier,
          timestamp,
          ancillaryData
        )
      {} catch {}
  }

  function proposePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) external override returns (uint256 totalBond) {
    return
      proposePriceFor(
        msg.sender,
        requester,
        identifier,
        timestamp,
        ancillaryData,
        proposedPrice
      );
  }

  function disputePriceFor(
    address disputer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public override nonReentrant() returns (uint256 totalBond) {
    require(disputer != address(0), 'disputer address must be non 0');
    require(
      getState(requester, identifier, timestamp, ancillaryData) ==
        State.Proposed,
      'disputePriceFor: Proposed'
    );
    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);
    request.disputer = disputer;

    uint256 finalFee = request.finalFee;
    uint256 bond = request.bond;
    totalBond = bond.add(finalFee);
    if (totalBond > 0) {
      request.currency.safeTransferFrom(msg.sender, address(this), totalBond);
    }

    StoreInterface store = _getStore();
    if (finalFee > 0) {
      uint256 burnedBond = _computeBurnedBond(request);

      uint256 totalFee = finalFee.add(burnedBond);
      request.currency.safeIncreaseAllowance(address(store), totalFee);
      _getStore().payOracleFeesErc20(
        address(request.currency),
        FixedPoint.Unsigned(totalFee)
      );
    }

    _getOracle().requestPrice(
      identifier,
      timestamp,
      _stampAncillaryData(ancillaryData, requester)
    );

    uint256 refund = 0;
    if (request.reward > 0 && request.refundOnDispute) {
      refund = request.reward;
      request.reward = 0;
      request.currency.safeTransfer(requester, refund);
    }

    emit DisputePrice(
      requester,
      request.proposer,
      disputer,
      identifier,
      timestamp,
      ancillaryData
    );

    if (address(requester).isContract())
      try
        OptimisticRequester(requester).priceDisputed(
          identifier,
          timestamp,
          ancillaryData,
          refund
        )
      {} catch {}
  }

  function disputePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override returns (uint256 totalBond) {
    return
      disputePriceFor(
        msg.sender,
        requester,
        identifier,
        timestamp,
        ancillaryData
      );
  }

  function settleAndGetPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override nonReentrant() returns (int256) {
    if (
      getState(msg.sender, identifier, timestamp, ancillaryData) !=
      State.Settled
    ) {
      _settle(msg.sender, identifier, timestamp, ancillaryData);
    }

    return
      _getRequest(msg.sender, identifier, timestamp, ancillaryData)
        .resolvedPrice;
  }

  function settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external override nonReentrant() returns (uint256 payout) {
    return _settle(requester, identifier, timestamp, ancillaryData);
  }

  function getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view override returns (Request memory) {
    return _getRequest(requester, identifier, timestamp, ancillaryData);
  }

  function getState(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view override returns (State) {
    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);

    if (address(request.currency) == address(0)) {
      return State.Invalid;
    }

    if (request.proposer == address(0)) {
      return State.Requested;
    }

    if (request.settled) {
      return State.Settled;
    }

    if (request.disputer == address(0)) {
      return
        request.expirationTime <= getCurrentTime()
          ? State.Expired
          : State.Proposed;
    }

    return
      _getOracle().hasPrice(
        identifier,
        timestamp,
        _stampAncillaryData(ancillaryData, requester)
      )
        ? State.Resolved
        : State.Disputed;
  }

  function hasPrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view override returns (bool) {
    State state = getState(requester, identifier, timestamp, ancillaryData);
    return
      state == State.Settled ||
      state == State.Resolved ||
      state == State.Expired;
  }

  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    pure
    returns (bytes memory)
  {
    return _stampAncillaryData(ancillaryData, requester);
  }

  function _getId(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) private pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(requester, identifier, timestamp, ancillaryData)
      );
  }

  function _settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) private returns (uint256 payout) {
    State state = getState(requester, identifier, timestamp, ancillaryData);

    Request storage request =
      _getRequest(requester, identifier, timestamp, ancillaryData);
    request.settled = true;

    if (state == State.Expired) {
      request.resolvedPrice = request.proposedPrice;
      payout = request.bond.add(request.finalFee).add(request.reward);
      request.currency.safeTransfer(request.proposer, payout);
    } else if (state == State.Resolved) {
      request.resolvedPrice = _getOracle().getPrice(
        identifier,
        timestamp,
        _stampAncillaryData(ancillaryData, requester)
      );
      bool disputeSuccess = request.resolvedPrice != request.proposedPrice;
      uint256 bond = request.bond;

      uint256 unburnedBond = bond.sub(_computeBurnedBond(request));

      payout = bond.add(unburnedBond).add(request.finalFee).add(request.reward);
      request.currency.safeTransfer(
        disputeSuccess ? request.disputer : request.proposer,
        payout
      );
    } else {
      revert('_settle: not settleable');
    }

    emit Settle(
      requester,
      request.proposer,
      request.disputer,
      identifier,
      timestamp,
      ancillaryData,
      request.resolvedPrice,
      payout
    );

    if (address(requester).isContract())
      try
        OptimisticRequester(requester).priceSettled(
          identifier,
          timestamp,
          ancillaryData,
          request.resolvedPrice
        )
      {} catch {}
  }

  function _getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) private view returns (Request storage) {
    return requests[_getId(requester, identifier, timestamp, ancillaryData)];
  }

  function _computeBurnedBond(Request storage request)
    private
    view
    returns (uint256)
  {
    return request.bond.div(2);
  }

  function _validateLiveness(uint256 _liveness) private pure {
    require(_liveness < 5200 weeks, 'Liveness too large');
    require(_liveness > 0, 'Liveness cannot be 0');
  }

  function _getOracle() internal view returns (OracleAncillaryInterface) {
    return
      OracleAncillaryInterface(
        finder.getImplementationAddress(OracleInterfaces.Oracle)
      );
  }

  function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
    return
      AddressWhitelist(
        finder.getImplementationAddress(OracleInterfaces.CollateralWhitelist)
      );
  }

  function _getStore() internal view returns (StoreInterface) {
    return
      StoreInterface(finder.getImplementationAddress(OracleInterfaces.Store));
  }

  function _getIdentifierWhitelist()
    internal
    view
    returns (IdentifierWhitelistInterface)
  {
    return
      IdentifierWhitelistInterface(
        finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist)
      );
  }

  function _stampAncillaryData(bytes memory ancillaryData, address requester)
    internal
    pure
    returns (bytes memory)
  {
    return abi.encodePacked(ancillaryData, 'OptimisticOracle', requester);
  }
}
