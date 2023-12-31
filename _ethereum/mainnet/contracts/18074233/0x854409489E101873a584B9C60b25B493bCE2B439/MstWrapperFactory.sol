// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./MstWrapper.sol";
import "./IMstWrapperFactory.sol";

import "./Ownable.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./ERC1967Proxy.sol";
import "./ERC1967Upgrade.sol";
import "./Clones.sol";
import "./BeaconProxy.sol";
import "./UpgradeableBeacon.sol";

/**
 * @title MstWrapperFactory
 * @author MetaStreet Labs
 */
contract MstWrapperFactory is Ownable, ERC1967Upgrade, IMstWrapperFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*--------------------------------------------------------------------------*/
    /* Constants                                                                */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /*--------------------------------------------------------------------------*/
    /* State                                                                    */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Initialized boolean
     */
    bool private _initialized;

    /**
     * @notice Set of deployed mstWrapper tokens
     */
    EnumerableSet.AddressSet private _mstWrapperTokens;

    /**
     * @notice Set of allowed mstWrapper implementations
     */
    EnumerableSet.AddressSet private _allowedImplementations;

    /*--------------------------------------------------------------------------*/
    /* Constructor                                                              */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice MstWrapperTokenFactory constructor
     */
    constructor() {
        /* Disable initialization of implementation contract */
        _initialized = true;

        /* Disable owner of implementation contract */
        renounceOwnership();
    }

    /*--------------------------------------------------------------------------*/
    /* Initializer                                                              */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice MstWrapperTokenFactory initializator
     */
    function initialize() external {
        require(!_initialized, "Already initialized");

        _initialized = true;
        _transferOwnership(msg.sender);
    }

    /*--------------------------------------------------------------------------*/
    /* Primary API                                                              */
    /*--------------------------------------------------------------------------*/

    /*
     * @inheritdoc IMstWrapperFactory
     */
    function create(address mstWrapperImplementation, bytes calldata params) external returns (address) {
        /* Validate mstWrapper implementation */
        if (!_allowedImplementations.contains(mstWrapperImplementation)) revert UnsupportedImplementation();

        /* Create mstWrapper instance */
        address mstWrapperInstance = Clones.clone(mstWrapperImplementation);
        Address.functionCall(mstWrapperInstance, abi.encodeWithSignature("initialize(bytes)", params));

        /* Add mstWrapper to registry */
        _mstWrapperTokens.add(mstWrapperInstance);

        /* Emit MstWrapper Token Created */
        emit MstWrapperCreated(mstWrapperInstance, mstWrapperImplementation);

        return mstWrapperInstance;
    }

    /*
     * @inheritdoc IMstWrapperFactory
     */
    function createProxied(address mstWrapperBeacon, bytes calldata params) external returns (address) {
        /* Validate mstWrapper implementation */
        if (!_allowedImplementations.contains(mstWrapperBeacon)) revert UnsupportedImplementation();

        /* Create mstWrapper instance */
        address mstWrapperInstance =
            address(new BeaconProxy(mstWrapperBeacon, abi.encodeWithSignature("initialize(bytes)", params)));

        /* Add mstWrapper to registry */
        _mstWrapperTokens.add(mstWrapperInstance);

        /* Emit MstWrapper Token Created */
        emit MstWrapperCreated(mstWrapperInstance, mstWrapperBeacon);

        return mstWrapperInstance;
    }

    /**
     * @inheritdoc IMstWrapperFactory
     */
    function isMstWrapperToken(address mstWrapperToken) external view returns (bool) {
        return _mstWrapperTokens.contains(mstWrapperToken);
    }

    /**
     * @inheritdoc IMstWrapperFactory
     */
    function getMstWrapperTokens() external view returns (address[] memory) {
        return _mstWrapperTokens.values();
    }

    /**
     * @inheritdoc IMstWrapperFactory
     */
    function getMstWrapperTokenCount() external view returns (uint256) {
        return _mstWrapperTokens.length();
    }

    /**
     * @inheritdoc IMstWrapperFactory
     */
    function getMstWrapperTokenAt(uint256 index) external view returns (address) {
        return _mstWrapperTokens.at(index);
    }

    /**
     * @inheritdoc IMstWrapperFactory
     */
    function getMstWrapperImplementations() external view returns (address[] memory) {
        return _allowedImplementations.values();
    }

    /*--------------------------------------------------------------------------*/
    /* Admin API                                                                */
    /*--------------------------------------------------------------------------*/

    /**
     * @notice Add mstWrapper implementation to allowlist
     */
    function addMstWrapperImplementation(address mstWrapperImplementation) external onlyOwner {
        if (_allowedImplementations.add(mstWrapperImplementation)) {
            emit MstWrapperImplementationAdded(mstWrapperImplementation);
        }
    }

    /**
     * @notice Remove mstWrapper implementation from allowlist
     */
    function removeMstWrapperImplementation(address mstWrapperImplementation) external onlyOwner {
        if (_allowedImplementations.remove(mstWrapperImplementation)) {
            emit MstWrapperImplementationRemoved(mstWrapperImplementation);
        }
    }

    /**
     * @notice Get Proxy Implementation
     * @return Implementation address
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Upgrade Proxy
     * @param newImplementation New implementation contract
     * @param data Optional calldata
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external onlyOwner {
        _upgradeToAndCall(newImplementation, data, false);
    }
}
