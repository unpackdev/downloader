// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./SafeOwnableUpgradeable.sol";
import "./ILiquidityPool.sol";
import "./IWETH9.sol";
import "./INativeUnwrapper.sol";
import "./LibOrder.sol";

contract Storage is Initializable, SafeOwnableUpgradeable {
    bool private _reserved1;
    mapping(address => bool) public brokers;
    ILiquidityPool internal _pool;
    uint64 public nextOrderId;
    LibOrder.OrderList internal _orders;
    IERC20Upgradeable internal _mlp;
    IWETH internal _weth;
    uint32 public liquidityLockPeriod; // 1e0
    INativeUnwrapper public _nativeUnwrapper;
    mapping(address => bool) public rebalancers;
    bool public isPositionOrderPaused;
    bool public isLiquidityOrderPaused;
    uint32 public marketOrderTimeout;
    uint32 public maxLimitOrderTimeout;
    address public maintainer;
    bytes32[44] _gap;

    modifier whenPositionOrderEnabled() {
        require(!isPositionOrderPaused, "POP"); // Position Order Paused
        _;
    }

    modifier whenLiquidityOrderEnabled() {
        require(!isLiquidityOrderPaused, "LOP"); // Liquidity Order Paused
        _;
    }
}
