// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ReentrancyGuard.sol";
import "./WadRayMath.sol";
import "./PoolRegistryStorage.sol";
import "./IPool.sol";
import "./Pauseable.sol";

error AddressIsNull();
error OracleIsNull();
error FeeCollectorIsNull();
error NativeTokenGatewayIsNull();
error AlreadyRegistered();
error UnregisteredPool();
error NewValueIsSameAsCurrent();

/**
 * @title PoolRegistry contract
 */
contract PoolRegistry is ReentrancyGuard, Pauseable, PoolRegistryStorageV2 {
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "1.3.0";

    /// @notice Emitted when fee collector is updated
    event FeeCollectorUpdated(address indexed oldFeeCollector, address indexed newFeeCollector);

    /// @notice Emitted when master oracle contract is updated
    event MasterOracleUpdated(IMasterOracle indexed oldOracle, IMasterOracle indexed newOracle);

    /// @notice Emitted when native token gateway is updated
    event NativeTokenGatewayUpdated(address indexed oldGateway, address indexed newGateway);

    /// @notice Emitted when a pool is registered
    event PoolRegistered(uint256 indexed id, address indexed pool);

    /// @notice Emitted when a pool is unregistered
    event PoolUnregistered(uint256 indexed id, address indexed pool);

    /// @notice Emitted when Swapper contract is updated
    event SwapperUpdated(ISwapper oldSwapFee, ISwapper newSwapFee);

    /// @notice Emitted when Quoter contract is updated
    event QuoterUpdated(IQuoter oldQuoter, IQuoter newQuoter);

    /// @notice Emitted when Cross-chain dispatcher contract is updated
    event CrossChainDispatcherUpdated(
        ICrossChainDispatcher oldCrossChainDispatcher,
        ICrossChainDispatcher newCrossChainDispatcher
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(IMasterOracle masterOracle_, address feeCollector_) external initializer {
        if (address(masterOracle_) == address(0)) revert OracleIsNull();
        if (feeCollector_ == address(0)) revert FeeCollectorIsNull();

        __ReentrancyGuard_init();
        __Pauseable_init();

        masterOracle = masterOracle_;
        feeCollector = feeCollector_;

        nextPoolId = 1;
    }

    /**
     * @notice Check if any pool has the token as part of its offerings
     * @param syntheticToken_ Asset to check
     * @return _exists Return true if exists
     */
    function doesSyntheticTokenExist(ISyntheticToken syntheticToken_) external view returns (bool _exists) {
        uint256 _length = pools.length();
        for (uint256 i; i < _length; ++i) {
            if (IPool(pools.at(i)).doesSyntheticTokenExist(syntheticToken_)) {
                return true;
            }
        }
    }

    /**
     * @notice Get all pools
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getPools() external view override returns (address[] memory) {
        return pools.values();
    }

    /**
     * @notice Check if pool is registered
     * @param pool_ Pool to check
     * @return true if exists
     */
    function isPoolRegistered(address pool_) external view override returns (bool) {
        return pools.contains(pool_);
    }

    /**
     * @notice Register pool
     */
    function registerPool(address pool_) external override onlyGovernor {
        if (pool_ == address(0)) revert AddressIsNull();
        if (!pools.add(pool_)) revert AlreadyRegistered();
        uint256 _id = idOfPool[pool_];
        if (_id == 0) {
            _id = nextPoolId++;
            idOfPool[pool_] = _id;
        }
        emit PoolRegistered(_id, pool_);
    }

    /**
     * @notice Unregister pool
     */
    function unregisterPool(address pool_) external override onlyGovernor {
        if (!pools.remove(pool_)) revert UnregisteredPool();
        emit PoolUnregistered(idOfPool[pool_], pool_);
    }

    /**
     * @notice Update fee collector
     */
    function updateFeeCollector(address newFeeCollector_) external override onlyGovernor {
        if (newFeeCollector_ == address(0)) revert FeeCollectorIsNull();
        address _currentFeeCollector = feeCollector;
        if (newFeeCollector_ == _currentFeeCollector) revert NewValueIsSameAsCurrent();
        emit FeeCollectorUpdated(_currentFeeCollector, newFeeCollector_);
        feeCollector = newFeeCollector_;
    }

    /**
     * @notice Update master oracle contract
     */
    function updateMasterOracle(IMasterOracle newMasterOracle_) external onlyGovernor {
        if (address(newMasterOracle_) == address(0)) revert OracleIsNull();
        IMasterOracle _currentMasterOracle = masterOracle;
        if (newMasterOracle_ == _currentMasterOracle) revert NewValueIsSameAsCurrent();
        emit MasterOracleUpdated(_currentMasterOracle, newMasterOracle_);
        masterOracle = newMasterOracle_;
    }

    /**
     * @notice Update native token gateway
     */
    function updateNativeTokenGateway(address newGateway_) external onlyGovernor {
        if (address(newGateway_) == address(0)) revert NativeTokenGatewayIsNull();
        address _currentGateway = nativeTokenGateway;
        if (newGateway_ == _currentGateway) revert NewValueIsSameAsCurrent();
        emit NativeTokenGatewayUpdated(_currentGateway, newGateway_);
        nativeTokenGateway = newGateway_;
    }

    /**
     * @notice Update Swapper contract
     */
    function updateSwapper(ISwapper newSwapper_) external onlyGovernor {
        if (address(newSwapper_) == address(0)) revert AddressIsNull();
        ISwapper _currentSwapper = swapper;
        if (newSwapper_ == _currentSwapper) revert NewValueIsSameAsCurrent();

        emit SwapperUpdated(_currentSwapper, newSwapper_);
        swapper = newSwapper_;
    }

    /**
     * @notice Update Quoter contract
     */
    function updateQuoter(IQuoter newQuoter_) external onlyGovernor {
        if (address(newQuoter_) == address(0)) revert AddressIsNull();
        IQuoter _currentQuoter = quoter;
        if (newQuoter_ == _currentQuoter) revert NewValueIsSameAsCurrent();

        emit QuoterUpdated(_currentQuoter, newQuoter_);
        quoter = newQuoter_;
    }

    /**
     * @notice Update Cross-chain dispatcher contract
     */
    function updateCrossChainDispatcher(ICrossChainDispatcher crossChainDispatcher_) external onlyGovernor {
        if (address(crossChainDispatcher_) == address(0)) revert AddressIsNull();
        ICrossChainDispatcher _current = crossChainDispatcher;
        if (crossChainDispatcher_ == _current) revert NewValueIsSameAsCurrent();

        emit CrossChainDispatcherUpdated(_current, crossChainDispatcher_);
        crossChainDispatcher = crossChainDispatcher_;
    }
}
