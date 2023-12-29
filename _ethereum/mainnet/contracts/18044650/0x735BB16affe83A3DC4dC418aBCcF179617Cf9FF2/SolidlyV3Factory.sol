// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./Status.sol";
import "./EnumerableSet.sol";
import "./ISolidlyV3Factory.sol";
import "./SolidlyV3PoolDeployer.sol";
import "./SolidlyV3Pool.sol";

/// @title Canonical Solidly V3 factory
/// @notice Deploys Solidly V3 pools and manages ownership and control over pool protocol fees
contract SolidlyV3Factory is ISolidlyV3Factory, SolidlyV3PoolDeployer {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Status for mapping(address => uint256);

    /// @inheritdoc ISolidlyV3Factory
    address public override owner;

    /// @inheritdoc ISolidlyV3Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc ISolidlyV3Factory
    mapping(address => mapping(address => mapping(int24 => address))) public override getPool;
    /// @inheritdoc ISolidlyV3Factory
    address public override feeCollector;
    /// @inheritdoc ISolidlyV3Factory
    mapping(address => uint256) public override isFeeSetter;

    EnumerableSet.AddressSet private feeSetters;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[100] = 1;
        emit FeeAmountEnabled(100, 1);
        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 50;
        emit FeeAmountEnabled(3000, 50);
        feeAmountTickSpacing[10000] = 100;
        emit FeeAmountEnabled(10000, 100);
    }

    /// @inheritdoc ISolidlyV3Factory
    function createPool(address tokenA, address tokenB, uint24 fee) external override returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][tickSpacing] == address(0));
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][tickSpacing] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][tickSpacing] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc ISolidlyV3Factory
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc ISolidlyV3Factory
    function setFeeCollector(address _feeCollector) external override {
        require(msg.sender == owner);
        emit FeeCollectorChanged(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /// @inheritdoc ISolidlyV3Factory
    function toggleFeeSetterStatus(address addr) external override {
        require(msg.sender == owner);
        uint256 newStatus = isFeeSetter.toggle(addr);
        newStatus == 1 ? feeSetters.add(addr) : feeSetters.remove(addr);
        emit FeeSetterStatusToggled(addr, newStatus);
    }

    /// @inheritdoc ISolidlyV3Factory
    function getFeeSetters() external view override returns (address[] memory) {
        return feeSetters.values();
    }

    /// @inheritdoc ISolidlyV3Factory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        // pool fee capped at 10%
        require(fee <= 100000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}
