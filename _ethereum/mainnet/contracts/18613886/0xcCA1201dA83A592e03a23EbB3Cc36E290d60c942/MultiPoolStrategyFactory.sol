// SPDX-License-Identifier: CC BY-NC-ND 4.0
pragma solidity ^0.8.19;

import "./Clones.sol";
import "./Ownable.sol";
import "./ConvexPoolAdapter.sol";
import "./MultiPoolStrategy.sol";
import "./AuraWeightedPoolAdapter.sol";
import "./AuraStablePoolAdapter.sol";
import "./AuraComposableStablePoolAdapter.sol";
import "./TransparentUpgradeableProxy.sol";
import "./AuraAdapterBase.sol";

contract MultiPoolStrategyFactory is Ownable {
    using Clones for address;

    address public convexAdapterImplementation;
    address public auraWeightedAdapterImplementation;
    address public auraStableAdapterImplementation;
    address public multiPoolStrategyImplementation;
    address public auraComposableStablePoolAdapterImplementation;
    address public monitor;
    address public proxyAdmin;

    constructor(
        address _monitor,
        address _convexPoolAdapterImplementation,
        address _multiPoolStrategyImplementation,
        address _auraWeightedAdapterImplementation,
        address _auraStableAdapterImplementation,
        address _auraComposableStablePoolAdapterImplementation,
        address _proxyAdmin
    )
        Ownable()
    {
        convexAdapterImplementation = _convexPoolAdapterImplementation;
        multiPoolStrategyImplementation = _multiPoolStrategyImplementation;
        auraWeightedAdapterImplementation = _auraWeightedAdapterImplementation;
        auraStableAdapterImplementation = _auraStableAdapterImplementation;
        auraComposableStablePoolAdapterImplementation = _auraComposableStablePoolAdapterImplementation;
        monitor = _monitor;
        proxyAdmin = _proxyAdmin;
    }

    function createConvexAdapter(
        address _curvePool,
        address _multiPoolStrategy,
        uint256 _convexPid,
        uint256 _tokensLength,
        address _zapper,
        bool _useEth,
        bool _indexUint,
        int128 _underlyingTokenIndex
    )
        external
        onlyOwner
        returns (address convexAdapter)
    {
        convexAdapter = convexAdapterImplementation.cloneDeterministic(
            keccak256(
                abi.encodePacked(
                    _curvePool,
                    _multiPoolStrategy,
                    _convexPid,
                    _tokensLength,
                    _zapper,
                    _useEth,
                    _indexUint,
                    _underlyingTokenIndex
                )
            )
        );
        bytes memory initData = abi.encodeWithSelector(
            ConvexPoolAdapter.initialize.selector,
            _curvePool,
            _multiPoolStrategy,
            _convexPid,
            _tokensLength,
            _zapper,
            _useEth,
            _indexUint,
            _underlyingTokenIndex
        );
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(convexAdapter,proxyAdmin,initData);

        convexAdapter = address(proxy);
    }

    function createAuraWeightedPoolAdapter(
        bytes32 _poolId,
        address _multiPoolStrategy,
        uint256 _auraPid
    )
        external
        onlyOwner
        returns (address auraAdapter)
    {
        auraAdapter = auraWeightedAdapterImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_poolId, _multiPoolStrategy, _auraPid))
        );
        bytes memory initData =
            abi.encodeWithSelector(AuraAdapterBase.initialize.selector, _poolId, _multiPoolStrategy, _auraPid);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(auraAdapter,proxyAdmin,initData);
        auraAdapter = address(proxy);
    }

    function createAuraStablePoolAdapter(
        bytes32 _poolId,
        address _multiPoolStrategy,
        uint256 _auraPid
    )
        external
        onlyOwner
        returns (address auraAdapter)
    {
        auraAdapter = auraStableAdapterImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_poolId, _multiPoolStrategy, _auraPid))
        );
        bytes memory initData =
            abi.encodeWithSelector(AuraAdapterBase.initialize.selector, _poolId, _multiPoolStrategy, _auraPid);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(auraAdapter,proxyAdmin,initData);
        auraAdapter = address(proxy);
    }

    function createAuraComposableStablePoolAdapter(
        bytes32 _poolId,
        address _multiPoolStrategy,
        uint256 _auraPid
    )
        external
        onlyOwner
        returns (address auraAdapter)
    {
        auraAdapter = auraComposableStablePoolAdapterImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_poolId, _multiPoolStrategy, _auraPid))
        );
        bytes memory initData =
            abi.encodeWithSelector(AuraAdapterBase.initialize.selector, _poolId, _multiPoolStrategy, _auraPid);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(auraAdapter,proxyAdmin,initData);
        auraAdapter = address(proxy);
    }

    /**
     * @dev Creates and initializes a new MultiPoolStrategy with the given parameters.
     * @param _underlyingToken The token that will be the underlying value asset in the strategy.
     * @param _salt A unique salt to produce a deterministic address when cloning the strategy.
     * @param _name Name of the strategy.
     * @param _symbol Symbol of the share token for the strategy.
     * @return multiPoolStrategy The address of the newly created MultiPoolStrategy.
     *
     * @notice Only the owner can call this function. The newly created strategy's ownership will
     * be transferred to the caller.
     */
    function createMultiPoolStrategy(
        address _underlyingToken,
        string calldata _salt,
        string calldata _name,
        string calldata _symbol
    )
        public
        onlyOwner
        returns (address multiPoolStrategy)
    {
        multiPoolStrategy = multiPoolStrategyImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_underlyingToken, monitor, _salt))
        );
        bytes memory initData =
            abi.encodeWithSelector(MultiPoolStrategy.initialize.selector, _underlyingToken, monitor, _name, _symbol);
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(multiPoolStrategy,proxyAdmin,initData);
        multiPoolStrategy = address(proxy);
        MultiPoolStrategy(multiPoolStrategy).transferOwnership(msg.sender);
    }

    function setMonitorAddress(address _newMonitor) external onlyOwner {
        monitor = _newMonitor;
    }

    //// Setters for adapter factory addresses
    function setConvexAdapterImplementation(address _newConvexAdapterImplementation) external onlyOwner {
        convexAdapterImplementation = _newConvexAdapterImplementation;
    }

    function setAuraStableImplementation(address _newAuraStableImplementation) external onlyOwner {
        auraStableAdapterImplementation = _newAuraStableImplementation;
    }

    function setAuraWeightedImplementation(address _newAuraWeightedImplementation) external onlyOwner {
        auraWeightedAdapterImplementation = _newAuraWeightedImplementation;
    }

    function setAuraComposableStableImplementation(address _newAuraComposableStableImplementation) external onlyOwner {
        auraComposableStablePoolAdapterImplementation = _newAuraComposableStableImplementation;
    }
}
