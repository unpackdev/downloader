// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./EnumerableSet.sol";
import "./IUniswapV2Router02.sol";
import "./IDexCenter.sol";
import "./ISRC20.sol";
import "./IPoolGuardian.sol";
import "./ITradingHub.sol";
import "./IPoolRewardModel.sol";
import "./IPriceOracle.sol";
import "./TitanCoreStorage.sol";
import "./EnumerableMap.sol";

contract TradingStorage is TitanCoreStorage {
    /// @notice Info of each pool, occupies 4 slots
    struct PoolInfo {
        address creator;
        // Staked single token contract
        ISRC20 stakedToken;
        ISRC20 stableToken;
        address strToken;
        // Allowed max leverage
        uint256 leverage;
        // Optional if the pool is marked as never expires(perputual)
        uint256 durationDays;
        // Pool creation block number
        uint256 startBlock;
        // Pool expired block number
        uint256 endBlock;
        uint256 id;
        uint256 stakedTokenDecimals;
        uint256 stableTokenDecimals;
        // Determining whether or not this pool is listed and present
        IPoolGuardian.PoolStatus stateFlag;
    }

    struct PositionCube {
        address addr;
        uint64 poolId;
    }

    struct PositionBlock {
        uint256 openBlock;
        uint256 closingBlock;
        uint256 overdrawnBlock;
        uint256 closedBlock;
    }

    struct PositionInfo {
        uint64 poolId;
        address strToken;
        ITradingHub.PositionState positionState;
    }

    bool internal _initialized;
    uint256 public allPositionSize;
    IDexCenter public dexCenter;
    IPoolGuardian public poolGuardian;
    IPriceOracle public priceOracle;
    IPoolRewardModel public poolRewardModel;

    mapping(uint256 => address) public allPositions;
    mapping(address => mapping(uint256 => PositionCube)) public userPositions;
    mapping(address => uint256) public userPositionSize;

    mapping(uint256 => mapping(uint256 => address)) public poolPositions;
    mapping(uint256 => uint256) public poolPositionSize;

    mapping(address => PositionInfo) public positionInfoMap;
    mapping(address => PositionBlock) public positionBlocks;
}
