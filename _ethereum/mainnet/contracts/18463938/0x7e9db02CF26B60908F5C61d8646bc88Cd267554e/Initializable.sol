// SPDX-License-Identifier: MIT
/// Adapted from OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.19;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint256 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    uint256 private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    uint256 internal constant _INITIALIZED_EVENT_SIGNATURE =
        0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498;

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        /// Cache `_initialized` to avoid SLOAD's
        uint256 cachedInitialized = _initialized;

        /// Cache `isTopLevelCall`
        bool isTopLevelCall = _initializing == 0;

        // Cache `_initialized` slot
        bytes32 cachedInitializingSlot;

        assembly ("memory-safe") {
            // Store `initializing` slot
            cachedInitializingSlot := _initializing.slot

            if and(
                iszero(and(eq(isTopLevelCall, 1), lt(cachedInitialized, 1))), // !(isTopLevelCall && _initialized < 1)
                iszero(and(iszero(extcodesize(address())), eq(cachedInitialized, 1))) // !(!Address.isContract(address(this)) && _initialized == 1)
            ) {
                // throw the `AlreadyInitialized` error
                mstore(0x00, 0x0dc149f0)
                revert(0x1c, 0x04)
            }

            sstore(_initialized.slot, 1) // Set `_initialized` to 1

            if eq(isTopLevelCall, 1) { sstore(cachedInitializingSlot, 1) } // Set `_initializing` to 1
        }

        _;

        assembly ("memory-safe") {
            if eq(isTopLevelCall, 1) {
                sstore(cachedInitializingSlot, 0) // Set `_initializing` to 0
                mstore(0x00, 0x01) // Store `version` of Initialized() event into memory
                log1(0x00, 0x20, _INITIALIZED_EVENT_SIGNATURE) // emit Initialized(1);
            }
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        // Cache `_initializing` slot
        bytes32 initializingSlot;

        assembly {
            // Store `initializing` slot
            initializingSlot := _initializing.slot
            // Cache `_initialized` slot
            let initializedSlot := _initialized.slot

            if iszero(
                and(
                    eq(sload(initializingSlot), 1), // !_initializing
                    lt(sload(initializedSlot), version) // _initialized < version
                )
            ) {
                // throw the `AlreadyInitialized` error
                mstore(0x00, 0x0dc149f0)
                revert(0x1c, 0x04)
            }

            sstore(initializedSlot, version) // update `_initialized` to version
            sstore(initializingSlot, 1) // set `_initializing` to 1
        }

        _;

        assembly ("memory-safe") {
            sstore(initializingSlot, 0) // set `_initializing` to 0
            mstore(0x00, version) // Store `version` of Initialized() event into memory
            log1(0x00, 0x20, _INITIALIZED_EVENT_SIGNATURE) // emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        assembly ("memory-safe") {
            if iszero(sload(_initializing.slot)) {
                // throw the `NotInitializing` error
                mstore(0x00, 0xd7e6bcf8)
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        assembly ("memory-safe") {
            if eq(sload(_initializing.slot), 1) {
                // if _initializing
                // throw the `AlreadyInitializing` error
                mstore(0x00, 0x593ae075)
                revert(0x1c, 0x04)
            }
            // Cache `_initialized` slot
            let initializedSlot := _initialized.slot
            if iszero(eq(sload(initializedSlot), not(0))) {
                // if _initialized != type(uint256).max
                sstore(initializedSlot, not(0))
            }

            mstore(0x00, not(0)) // Store `type(uint256).max` of Initialized() as new version
            log1(0x00, 0x20, _INITIALIZED_EVENT_SIGNATURE) // emit Initialized(version);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint256) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (uint256) {
        return _initializing;
    }
}
