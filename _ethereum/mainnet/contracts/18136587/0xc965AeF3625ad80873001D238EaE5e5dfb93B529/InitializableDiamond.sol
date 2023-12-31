// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)
pragma solidity 0.8.9;

import "./LibInitializer.sol";

/**
 * @dev External interface of LibInitializer
 */
abstract contract InitializableDiamond {
    /// @dev Emitted when the contract has been initialized or reinitialized.
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * @dev `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * @dev Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * @dev constructor.
     *
     * @dev Emits an {Initialized} event.
     */
    modifier initializer(address initContract) {
        LibInitializer._beforeInitializer(1, initContract);
        _;
        LibInitializer._afterInitializer(1, initContract);
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * @dev contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * @dev used to initialize parent contracts.
     *
     * @dev A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * @dev are added through upgrades and that require initialization.
     *
     * @dev When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * @dev cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * @dev Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * @dev a contract, executing them in the right order is up to the developer or operator.
     *
     * @dev WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * @dev Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version, address initContract) {
        LibInitializer._beforeInitializer(version, initContract);
        _;
        LibInitializer._afterInitializer(version, initContract);        
    }

    /**
     * @dev A modifier that requires the function to be invoked during initialization. This is useful to prevent
     * @dev initialization functions from being invoked by users or other contracts.
     */
    modifier onlyInitializing(address initContract) {
        LibInitializer._requireInitializing(initContract);
        _;
    }
}
