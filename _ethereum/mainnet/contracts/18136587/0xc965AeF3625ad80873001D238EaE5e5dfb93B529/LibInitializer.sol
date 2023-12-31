// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library LibInitializer {
    
    error Initializable__ContractIsNotInitializing();
    error Initializable__ContractIsInitializing();
    error Initializable__ContractAlreadyInitialized();

    struct InitializerStorage {
        mapping(address => uint8) _initialized;
        mapping(address => bool) _initializing;
    }

    /// @dev Storage slot to use for Access Control specific storage
    bytes32 internal constant STORAGE_SLOT = keccak256("adventurehub.storage.Initializer");

    /// @dev Emitted when the contract has been initialized or reinitialized.
    event Initialized(uint8 version);

    /**
     * @dev Enforces that a function can only be invoked by functions during initialization
     */
    function _requireInitializing(address initContract) internal view {
        if(!initializerStorage()._initializing[initContract]) {
            revert Initializable__ContractIsNotInitializing();
        }
    }

    /// @dev Sets values to protect functions during initialization
    function _beforeInitializer(uint8 version, address initContract) internal {
        if (initializerStorage()._initializing[initContract]) {
            revert Initializable__ContractIsInitializing();
        }
        if (initializerStorage()._initialized[initContract] >= version) {
            revert Initializable__ContractAlreadyInitialized();
        }
        initializerStorage()._initialized[initContract] = version;
        initializerStorage()._initializing[initContract] = true;
    }

    /// @dev Unsets values after initialization functions are complete
    function _afterInitializer(uint8 version, address initContract) internal {
        if (initializerStorage()._initializing[initContract]) {
            initializerStorage()._initializing[initContract] = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * @dev Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * @dev to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * @dev through proxies.
     *
     * @dev Throws if the contract is currently initializing.
     * @dev No-op if the contract has already been locked.
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. Emits an Initialized event.
     * @dev 2. The `_initialized` is set to `type(uint8).max`, locking the contract.
     */
    function _disableInitializers(address initContract) internal {
        if (initializerStorage()._initializing[initContract]) {
            revert Initializable__ContractIsInitializing();
        }
        if (initializerStorage()._initialized[initContract] < type(uint8).max) {
            initializerStorage()._initialized[initContract] = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /// @dev Returns the highest version that has been initialized
    function _getInitializedVersion(address initContract) internal view returns (uint8) {
        return initializerStorage()._initialized[initContract];
    }

    /// @dev Returns `true` if the contract is currently initializing, false if not.
    function _isInitializing(address initContract) internal view returns (bool) {
        return initializerStorage()._initializing[initContract];
    }

    /// @dev Returns the storage data stored at the `STORAGE_SLOT`
    function initializerStorage() internal pure returns (InitializerStorage storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
