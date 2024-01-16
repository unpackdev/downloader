// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import "./AddressUpgradeable.sol";
import "./Initializable.sol";

abstract contract AfterInitializable {
    /**
     * @dev Indicates that the contract has been AfterInitialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _AfterInitialized;

    /**
     * @dev Indicates that the contract is in the process of being AfterInitialized.
     */
    bool private _afterinitializing;

    /**
     * @dev Triggered when the contract has been AfterInitialized or reAfterInitialized.
     */
    event AfterInitialized(uint8 version);

    modifier afterInitializer() {
        bool isTopLevelCall = !_afterinitializing;
        require(
            (isTopLevelCall && _AfterInitialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _AfterInitialized == 1),
            "AfterInitializable: contract is already AfterInitialized"
        );
        _AfterInitialized = 1;
        if (isTopLevelCall) {
            _afterinitializing = true;
        }
        _;
        if (isTopLevelCall) {
            _afterinitializing = false;
            emit AfterInitialized(1);
        }
    }

    modifier reAfterInitializer(uint8 version) {
        require(
            !_afterinitializing && _AfterInitialized < version,
            "AfterInitializable: contract is already AfterInitialized"
        );
        _AfterInitialized = version;
        _afterinitializing = true;
        _;
        _afterinitializing = false;
        emit AfterInitialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {AfterInitializer} and {reAfterInitializer} modifiers, directly or indirectly.
     */
    modifier onlyAfterInitializing() {
        require(
            _afterinitializing,
            "AfterInitializable: contract is not initializing"
        );
        _;
    }

    function _disableAfterInitializers() internal virtual {
        require(
            !_afterinitializing,
            "AfterInitializable: contract is initializing"
        );
        if (_AfterInitialized < type(uint8).max) {
            _AfterInitialized = type(uint8).max;
            emit AfterInitialized(type(uint8).max);
        }
    }
}
