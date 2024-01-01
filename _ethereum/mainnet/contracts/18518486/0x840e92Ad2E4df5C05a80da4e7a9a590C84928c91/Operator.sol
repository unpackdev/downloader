// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUSDV.sol";
import "./IOperator.sol";
import "./RateLimiter.sol";

contract Operator is IOperator, Ownable {
    using SafeERC20 for IERC20;
    using RateLimiter for RateLimiter.Info;

    IUSDV public immutable usdv;

    uint64 public operatorRemintFeeMin;
    uint16 public operatorRemintFeeBps = 3;
    uint64 public minterRemintFeeMin;
    uint16 public minterRemintFeeBps = 0;
    uint64 public syncFeeMin;
    uint16 public syncFeeBps;

    uint64 public syncDeltaSizeLimit = 20;
    uint64 public remintDeltaSizeLimit = 20;

    RateLimiter.Info public rateLimiter; // used for send/sendAck

    error InvalidBps();
    error NotUSDV();
    error InvalidDeltaSize();

    event ChangedOperatorRemintFee(uint16 bps, uint64 min);
    event ChangedMinterRemintFee(uint16 bps, uint64 min);
    event ChangedSyncFee(uint16 bps, uint64 min);
    event SetCapacity(uint64 _capacity);
    event SetRate(uint64 _rate);
    event SetSyncDeltaSizeLimit(uint64 _limit);
    event SetRemintDeltaSizeLimit(uint64 _limit);

    constructor(IUSDV _usdv, address _owner) Ownable() {
        usdv = _usdv;
        _transferOwnership(_owner);
    }

    modifier onlyUSDV() {
        if (msg.sender != address(usdv)) revert NotUSDV();
        _;
    }

    // ========================= OnlyOwner =========================
    function rotateOperator(address _addr) external onlyOwner {
        usdv.setRole(Role.OPERATOR, _addr);
    }

    function withdrawToken(address _token, address _to, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function setPause(bool _pause) external onlyOwner {
        usdv.setPause(_pause);
    }

    function setOperatorRemintFee(uint16 _bps, uint64 _min) external onlyOwner {
        if (minterRemintFeeBps + _bps > 10000) revert InvalidBps();
        operatorRemintFeeBps = _bps;
        operatorRemintFeeMin = _min;
        emit ChangedOperatorRemintFee(_bps, _min);
    }

    function setMinterRemintFee(uint16 _bps, uint64 _min) external onlyOwner {
        if (operatorRemintFeeBps + _bps > 10000) revert InvalidBps();
        minterRemintFeeBps = _bps;
        minterRemintFeeMin = _min;
        emit ChangedMinterRemintFee(_bps, _min);
    }

    function setSyncFee(uint16 _bps, uint64 _min) external onlyOwner {
        if (_bps > 10000) revert InvalidBps();
        syncFeeBps = _bps;
        syncFeeMin = _min;
        emit ChangedSyncFee(_bps, _min);
    }

    function setColorer(address _user, address _colorer) external onlyOwner {
        usdv.setColorer(_user, _colorer);
    }

    function setDefaultColor(address _user, uint32 _color) external onlyOwner {
        usdv.setDefaultColor(_user, _color);
    }

    function setCapacityForSend(uint64 _capacity) external onlyOwner {
        rateLimiter.setCapacity(_capacity);
        emit SetCapacity(_capacity);
    }

    function setRateForSend(uint64 _rate) external onlyOwner {
        rateLimiter.setRate(_rate);
        emit SetRate(_rate);
    }

    function setSyncDeltaSizeLimit(uint64 _limit) external onlyOwner {
        syncDeltaSizeLimit = _limit;
        emit SetSyncDeltaSizeLimit(_limit);
    }

    function setRemintDeltaSizeLimit(uint64 _limit) external onlyOwner {
        remintDeltaSizeLimit = _limit;
        emit SetRemintDeltaSizeLimit(_limit);
    }

    // ========================= OnlyUSDV =========================
    function tryConsume(address /*_caller*/, uint64 _amount) external onlyUSDV returns (uint64) {
        return rateLimiter.tryConsume(_amount);
    }

    function refill(address /*_caller*/, uint64 _extraTokens) external onlyUSDV {
        rateLimiter.refill(_extraTokens);
    }

    // ========================= View =========================
    function getSyncFees(
        address /*_caller*/,
        Delta[] calldata deltas,
        uint64 _usdvAmount
    ) external view returns (uint64 syncFee) {
        if (deltas.length > syncDeltaSizeLimit) revert InvalidDeltaSize();
        syncFee = uint64((uint(_usdvAmount) * syncFeeBps) / 10000);
        syncFee = syncFee < syncFeeMin ? syncFeeMin : syncFee;
    }

    function getRemintFees(
        address /*_caller*/,
        uint32 /*_toColor*/,
        Delta[] calldata deltas,
        uint64 _usdvAmount
    ) external view returns (uint64 minterFee, uint64 operatorFee) {
        if (deltas.length > remintDeltaSizeLimit) revert InvalidDeltaSize();
        minterFee = uint64((uint(_usdvAmount) * minterRemintFeeBps) / 10000);
        minterFee = minterFee < minterRemintFeeMin ? minterRemintFeeMin : minterFee;
        operatorFee = uint64((uint(_usdvAmount) * operatorRemintFeeBps) / 10000);
        operatorFee = operatorFee < operatorRemintFeeMin ? operatorRemintFeeMin : operatorFee;
    }
}
