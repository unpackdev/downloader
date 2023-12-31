// SPDX-License-Identifier: CC BY-NC-ND 4.0
pragma solidity ^0.8.19;

import "./Clones.sol";
import "./Ownable.sol";
import "./ConvexPoolAdapter.sol";
import "./MultiPoolStrategy.sol";
import "./AuraWeightedPoolAdapter.sol";
import "./AuraStablePoolAdapter.sol";
import "./AuraComposableStablePoolAdapter.sol";

contract MultiPoolStrategyFactory is Ownable {
    using Clones for address;

    address public convexAdapterImplementation;
    address public auraWeightedAdapterImplementation;
    address public auraStableAdapterImplementation;
    address public multiPoolStrategyImplementation;
    address public auraComposableStablePoolAdapterImplementation;
    address public monitor;

    constructor(
        address _monitor,
        address _convexPoolAdapterImplementation,
        address _multiPoolStrategyImplementation,
        address _auraWeightedAdapterImplementation,
        address _auraStableAdapterImplementation,
        address _auraComposableStablePoolAdapterImplementation
    )
        Ownable()
    {
        convexAdapterImplementation = _convexPoolAdapterImplementation;
        multiPoolStrategyImplementation = _multiPoolStrategyImplementation;
        auraWeightedAdapterImplementation = _auraWeightedAdapterImplementation;
        auraStableAdapterImplementation = _auraStableAdapterImplementation;
        auraComposableStablePoolAdapterImplementation = _auraComposableStablePoolAdapterImplementation;
        monitor = _monitor;
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
        ConvexPoolAdapter(payable(convexAdapter)).initialize(
            _curvePool,
            _multiPoolStrategy,
            _convexPid,
            _tokensLength,
            _zapper,
            _useEth,
            _indexUint,
            _underlyingTokenIndex
        );
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
        AuraWeightedPoolAdapter(payable(auraAdapter)).initialize(_poolId, _multiPoolStrategy, _auraPid);
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
        AuraStablePoolAdapter(payable(auraAdapter)).initialize(_poolId, _multiPoolStrategy, _auraPid);
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
        AuraComposableStablePoolAdapter(payable(auraAdapter)).initialize(_poolId, _multiPoolStrategy, _auraPid);
    }

    /**
    * @dev Creates and initializes a new MultiPoolStrategy with the given parameters.
    * @param _underlyingToken The token that will be the underlying value asset in the strategy.
    * @param _salt A unique salt to produce a deterministic address when cloning the strategy.
    * @return multiPoolStrategy The address of the newly created MultiPoolStrategy.
    * 
    * @notice Only the owner can call this function. The newly created strategy's ownership will
    * be transferred to the caller.
    */
    function createMultiPoolStrategy(
        address _underlyingToken,
        string calldata _salt
    )
        external
        onlyOwner
        returns (address multiPoolStrategy)
    {
        multiPoolStrategy = multiPoolStrategyImplementation.cloneDeterministic(
            keccak256(abi.encodePacked(_underlyingToken, monitor, _salt))
        );
        MultiPoolStrategy(multiPoolStrategy).initialize(_underlyingToken, monitor);
        MultiPoolStrategy(multiPoolStrategy).transferOwnership(msg.sender);    
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
        MultiPoolStrategy(multiPoolStrategy).initialize(_underlyingToken, monitor, _name,  _symbol);
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
