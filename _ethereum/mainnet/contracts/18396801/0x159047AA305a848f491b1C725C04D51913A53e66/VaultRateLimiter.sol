// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "./Ownable.sol";
import "./IVaultRateLimiter.sol";
import "./RateLimiter.sol";

contract VaultRateLimiter is Ownable, IVaultRateLimiter {
    using RateLimiter for RateLimiter.Info;

    event SetOperator(address _operator);
    event SetCapacity(uint64 _capacity, bool _isMint);
    event SetRate(uint64 _rate, bool _isMint);

    address public operator;
    address public immutable vaultManager;
    mapping(address asset => RateLimiter.Info) public mintRateLimiter;
    mapping(address asset => RateLimiter.Info) public burnRateLimiter;

    modifier onlyOperator() {
        if (msg.sender != operator) revert Unauthorized();
        _;
    }

    modifier onlyVaultManager() {
        if (msg.sender != vaultManager) revert Unauthorized();
        _;
    }

    constructor(address _operator, address _vaultManager) {
        operator = _operator;
        vaultManager = _vaultManager;
    }

    // ========================= OnlyOwner =========================
    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    // ========================= OnlyOperator =========================
    function setCapacityForMint(address _asset, uint64 _capacity) external onlyOperator {
        mintRateLimiter[_asset].setCapacity(_capacity);
        emit SetCapacity(_capacity, true);
    }

    function setRateForMint(address _asset, uint64 _rate) external onlyOperator {
        mintRateLimiter[_asset].setRate(_rate);
        emit SetRate(_rate, true);
    }

    function setCapacityForBurn(address _asset, uint64 _capacity) external onlyOperator {
        burnRateLimiter[_asset].setCapacity(_capacity);
        emit SetCapacity(_capacity, false);
    }

    function setRateForBurn(address _asset, uint64 _rate) external onlyOperator {
        burnRateLimiter[_asset].setRate(_rate);
        emit SetRate(_rate, false);
    }

    // ========================= OnlyVaultManager =========================
    function tryMint(address /*_caller*/, address _asset, uint64 _amount) external onlyVaultManager returns (uint64) {
        return mintRateLimiter[_asset].tryConsume(_amount);
    }

    function tryBurn(address /*_caller*/, address _asset, uint64 _amount) external onlyVaultManager {
        burnRateLimiter[_asset].tryConsume(_amount);
    }
}
