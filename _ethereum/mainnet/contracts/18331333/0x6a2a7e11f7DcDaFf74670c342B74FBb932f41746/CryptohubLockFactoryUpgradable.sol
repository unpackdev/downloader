pragma solidity ^0.8.19;


// 
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)
/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// 
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)
/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)
/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)
/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.
/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)
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
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)
/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)
/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)
/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// 
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//
contract AccessControlUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _admins;

    function __AccessControlUpgradeable_init(
        address[] memory _adminsArgs
    ) internal initializer {
        for (uint256 i = 0; i < _adminsArgs.length; i++) {
            _admins[_adminsArgs[i]] = true;
        }
    }

    function addAdmin(address _admin) external onlyOwner {
        _admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
        _admins[_admin] = false;
    }

    function renounceAdmin() external {
        _admins[msg.sender] = false;
    }

    function isAdmin(address _admin) public view returns (bool) {
        return _admins[_admin] || _admin == owner();
    }

    modifier onlyAdmin() {
        require(
            _admins[msg.sender] || owner() == msg.sender,
            "AccessControl: only admin"
        );
        _;
    }

    uint256[50] private __gap;
}

//
struct Price {
    address asset;
    uint256 product;
    uint256 price;
}

contract PlatformsSystemUpgradable is AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint256 => uint256) private cryptohubCommission;

    mapping(address => mapping(uint256 => uint256)) private _baseFees;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _platformsFees;

    mapping(uint256 => address) private _platformsReceivers;

    address private _treasury;

    event PaimentReceived(
        uint256 indexed platform,
        address indexed asset,
        address indexed user,
        uint256 platformAmount,
        uint256 cryptohubAmount
    );

    modifier onlyReceiverOrAdmin(uint256 platform) {
        require(
            _platformsReceivers[platform] == msg.sender || isAdmin(msg.sender),
            "PlatformsSystemUpgradable: only receiver or admin"
        );
        _;
    }

    function _checkPayment(
        uint256 _platform,
        address _paymentAsset,
        uint256 _template,
        uint256 _ethUnrelatedAmount
    ) internal {
        (uint256 platfromPrice, address platfromReceiver) = _getPrice(
            _platform,
            _paymentAsset,
            _template
        );
        (uint256 commission, address cryptohubReceiver) = _cryptohubCommission(
            _platform,
            platfromPrice
        );
        require(
            platfromPrice > 0 || _paymentAsset == address(0),
            "PlatformsSystem: not supported asset"
        );

        if (_paymentAsset == address(0)) {
            require(
                msg.value >= platfromPrice + _ethUnrelatedAmount,
                "PlatformsSystem: Insufficient Payment"
            );
            (bool success, ) = payable(platfromReceiver).call{
                value: platfromPrice - commission
            }("");
            require(success, "PlatformsSystem: failed to transfer");
            (success, ) = payable(cryptohubReceiver).call{value: commission}(
                ""
            );
            require(success, "PlatformsSystem: failed to transfer");
        } else {
            // transfer payment
            IERC20Upgradeable(_paymentAsset).safeTransferFrom(
                msg.sender,
                platfromReceiver,
                platfromPrice - commission
            );
            if (commission > 0)
                IERC20Upgradeable(_paymentAsset).safeTransferFrom(
                    msg.sender,
                    cryptohubReceiver,
                    commission
                );
        }

        emit PaimentReceived(
            _platform,
            _paymentAsset,
            msg.sender,
            platfromPrice - commission,
            commission
        );
    }

    function __PlatformsSystemUpgradable_init(
        address _treasury_,
        uint256[] memory _commissionRates,
        Price[] memory _baseFees_,
        address[] memory _receivers,
        Price[][] memory _platformsFees_
    ) internal initializer {
        _treasury = _treasury_;
        for (uint256 i = 0; i < _commissionRates.length; i++) {
            _setCryptoHubCommission(i, _commissionRates[i]);
        }
        for (uint256 i = 0; i < _baseFees_.length; i++) {
            _setBaseFee(
                _baseFees_[i].asset,
                _baseFees_[i].product,
                _baseFees_[i].price
            );
        }
        for (uint256 i = 0; i < _receivers.length; i++) {
            _setPlatformReceiver(i, _receivers[i]);
        }

        for (uint256 i = 0; i < _platformsFees_.length; i++) {
            for (uint256 j = 0; j < _platformsFees_[i].length; j++) {
                _setPlatformFee(
                    i,
                    _platformsFees_[i][j].asset,
                    _platformsFees_[i][j].product,
                    _platformsFees_[i][j].price
                );
            }
        }
    }

    function getPlatformFee(
        uint256 _platform,
        address _assets,
        uint256[] calldata _products
    ) external view returns (uint256[] memory fees) {
        uint256[] memory _fees = new uint256[](_products.length);
        for (uint256 i = 0; i < _products.length; i++) {
            _fees[i] = _platformsFees[_platform][_assets][_products[i]];
        }
        return _fees;
    }

    function getPlatformReceiver(
        uint256 _platform
    ) external view returns (address) {
        return _platformsReceivers[_platform];
    }

    function getBaseFees(
        address _assets,
        uint256[] calldata _products
    ) external view returns (uint256[] memory fees) {
        uint256[] memory _fees = new uint256[](_products.length);
        for (uint256 i = 0; i < _products.length; i++) {
            _fees[i] = _baseFees[_assets][_products[i]];
        }
        return _fees;
    }

    function _cryptohubCommission(
        uint256 _platform,
        uint256 _amount
    ) internal view returns (uint256, address) {
        return ((_amount * cryptohubCommission[_platform]) / 100, _treasury);
    }

    function _getPrice(
        uint256 _platform,
        address _asset,
        uint256 _product
    ) internal view returns (uint256, address) {
        return (
            _platformsFees[_platform][_asset][_product],
            _platformsReceivers[_platform]
        );
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function _setTreasury(address _treasury_) internal {
        _treasury = _treasury_;
    }

    function setTreasury(address _treasury_) external onlyAdmin {
        _setTreasury(_treasury_);
    }

    function setCryptoHubCommission(
        uint256 _platform,
        uint256 _amount
    ) external onlyAdmin {
        _setCryptoHubCommission(_platform, _amount);
    }

    function _setCryptoHubCommission(
        uint256 _platform,
        uint256 _amount
    ) internal {
        require(_amount <= 65, "CryptoHubERC20Factory: commission too high");
        cryptohubCommission[_platform] = _amount;
    }

    function baseFees(
        uint256 _product,
        address _asset
    ) public view returns (uint256) {
        return _baseFees[_asset][_product];
    }

    function setBaseFee(address _asset, uint256 _amount) external onlyAdmin {
        _setBaseFee(_asset, 0, _amount);
    }

    function setManyBaseFee(Price[] calldata _prices) external onlyAdmin {
        for (uint256 i = 0; i < _prices.length; i++) {
            _setBaseFee(_prices[i].asset, _prices[i].product, _prices[i].price);
        }
    }

    function _setBaseFee(
        address _asset,
        uint256 _product,
        uint256 _amount
    ) internal {
        _baseFees[_asset][_product] = _amount;
    }

    function setPlatformFee(
        uint256 _platform,
        address _asset,
        uint256 _product,
        uint256 _amount
    ) public onlyReceiverOrAdmin(_platform) {
        _setPlatformFee(_platform, _asset, _product, _amount);
    }

    function _setPlatformFee(
        uint256 _platform,
        address _asset,
        uint256 _product,
        uint256 _amount
    ) internal {
        _platformsFees[_platform][_asset][_product] = _amount;
    }

    function setManyPlatformFee(
        uint256 _platform,
        Price[] calldata _prices
    ) external {
        for (uint256 i = 0; i < _prices.length; i++)
            setPlatformFee(
                _platform,
                _prices[i].asset,
                _prices[i].product,
                _prices[i].price
            );
    }

    function setPlatformReceiver(
        uint256 _platform,
        address _receiver
    ) public onlyReceiverOrAdmin(_platform) {
        _setPlatformReceiver(_platform, _receiver);
    }

    function _setPlatformReceiver(
        uint256 _platform,
        address _receiver
    ) internal {
        _platformsReceivers[_platform] = _receiver;
    }

    function setManyPlatformReceiver(
        uint256[] calldata _platforms,
        address[] calldata _receivers
    ) external {
        for (uint256 i = 0; i < _platforms.length; i++) {
            setPlatformReceiver(_platforms[i], _receivers[i]);
        }
    }

    function getCryptoHubCommission(
        uint256 _platform
    ) external view returns (uint256) {
        return cryptohubCommission[_platform];
    }

    uint256[50] private __gap;
}

//
contract CreditManagementUpgradable is AccessControlUpgradeable {
    mapping(uint256 => mapping(address => uint256)) private _credits;

    /**
     * @dev Increase credits for a user
     * @notice This function can only be called by an admin
     * @param _platform The platform to get credits for
     * @param _user The user to get credits for
     * @param _amount The amount of credits to get
     */
    function increaseCredits(
        uint256 _platform,
        address _user,
        uint256 _amount
    ) external onlyAdmin {
        _credits[_platform][_user] += _amount;
    }

    /**
     * @dev Decrease credits for a user
     * @notice If the user does not have enough credits, set to 0
     * @param _platform The platform to get credits for
     * @param _user The user to decrease credits for
     * @param _amount The amount of credits to decrease
     */
    function decreaseCredits(
        uint256 _platform,
        address _user,
        uint256 _amount
    ) external onlyAdmin {
        if (_credits[_platform][_user] >= _amount)
            _credits[_platform][_user] -= _amount;
        else _credits[_platform][_user] = 0;
    }

    function _getCredits(
        uint256 _platform,
        address _user
    ) internal view returns (uint256) {
        return _credits[_platform][_user];
    }

    function _decreaseCredits(
        uint256 _platform,
        address _user,
        uint256 _amount
    ) internal {
        // setting max uint256 to credits means infinite credits
        // this will be used by the presale platform etc...
        if (_credits[_platform][_user] == type(uint256).max) return;

        require(
            _credits[_platform][_user] >= _amount,
            "CreditManagement: not enough credits"
        );
        _credits[_platform][_user] -= _amount;
    }

    function _increaseCredits(
        uint256 _platform,
        address _user,
        uint256 _amount
    ) internal {
        _credits[_platform][_user] += _amount;
    }

    function userCredits(
        uint256 _platform,
        address _user
    ) external view returns (uint256) {
        return _credits[_platform][_user];
    }

    uint256[50] private __gap;
}

// 
interface ILockHolder {
    function transfer(address token, address to, uint256 amount) external;
}

interface ILockFactory {
    function holderOwner(address _holder) external view returns (address);
}

contract LockHolder is ILockHolder {
    address public immutable lockFactory;

    receive() external payable {}

    constructor(address _lockFactory) {
        lockFactory = _lockFactory;
    }

    function transfer(address token, address to, uint256 amount) external {
        require(msg.sender == lockFactory, "LockHolder: UNAUTHORIZED");
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "LockHolder: ETH_TRANSFER_FAILED");
            return;
        }
        (bool _success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(
            _success && (data.length == 0 || abi.decode(data, (bool))),
            "LockHolder: TRANSFER_FAILED"
        );
    }

    function owner() external view returns (address) {
        return ILockFactory(lockFactory).holderOwner(address(this));
    }
}

// 
// import clones
// import "./console.sol";
uint256 constant RATIOS_PRECISION = 10000;

// used to calculate ratios with 4 decimals of precision
struct LockData {
    // perfect 128 bytes
    address asset; // 20 bytes
    address receiver; // 20 bytes
    address holder; // 20 bytes
    uint48 vestingStart; // 6 bytes
    uint16 firstUnlockRatio; // 2 bytes
    uint48 unlockInterval; // 6 bytes
    uint48 lockDuration; // 6 bytes
    uint192 totalAmount; // 24 bytes
    uint192 amountWithdrawn; // 24 bytes
}

struct FullLock {
    address asset;
    address receiver;
    address holder;
    uint48 vestingStart;
    uint16 firstUnlockRatio;
    uint48 unlockInterval;
    uint48 lockDuration;
    uint192 totalAmount;
    uint192 amountWithdrawn;
    uint256 unlockedAmount;
    uint256 amountAvailable;
}

library LockHolderUtils {
    function predictLockAddress(
        address _deployer,
        address _implementationAddress,
        address _receiver
    ) internal pure returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_receiver));

        return
            ClonesUpgradeable.predictDeterministicAddress(
                _implementationAddress,
                _salt,
                _deployer
            );
    }
}

contract LockerFactoryStorageUpgradable is
    AccessControlUpgradeable,
    PlatformsSystemUpgradable,
    CreditManagementUpgradable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint256 => LockData[]) public locks;

    mapping(address => address) public userHolders;

    address public lockHolderImplementation;

    event LockCreated(
        uint256 indexed _platform,
        uint256 lockId,
        bytes32 reason
    );

    event LockAmountUpdated(
        uint256 indexed _platform,
        uint256 lockId,
        uint256 newAmount
    );

    function __CryptohubLock_init(
        address[] memory _adminsArgs,
        address _treasury_,
        uint256[] memory _commissionRates,
        Price[] memory _baseFees_,
        address[] memory _receivers,
        Price[][] memory _platformsFees_
    ) internal initializer {
        __AccessControlUpgradeable_init(_adminsArgs);
        __PlatformsSystemUpgradable_init(
            _treasury_,
            _commissionRates,
            _baseFees_,
            _receivers,
            _platformsFees_
        );

        lockHolderImplementation = address(new LockHolder(address(this)));
    }

    struct LockArg {
        uint256 platform;
        address asset;
        address receiver;
        uint48 vestingStart;
        uint16 firstUnlockRatio;
        uint48 unlockInterval;
        uint48 lockDuration;
        uint192 totalAmount;
        bytes32 reason;
        bool allowTax;
        address paymentAsset;
    }

    function lock(LockArg memory _lockArg) external payable {
        require(
            _lockArg.firstUnlockRatio <= RATIOS_PRECISION,
            "CryptohubLock: INVALID_FIRST_UNLOCK_RATIO"
        );
        require(
            _lockArg.lockDuration >= _lockArg.unlockInterval,
            "CryptohubLock: INVALID_LOCK_DURATION"
        );
        require(
            _lockArg.vestingStart > block.timestamp,
            "CryptohubLock: INVALID_VESTING_START"
        );

        if (_getCredits(_lockArg.platform, msg.sender) > 0) {
            _decreaseCredits(_lockArg.platform, msg.sender, 1);
        } else {
            _checkPayment(
                _lockArg.platform,
                _lockArg.paymentAsset,
                0,
                _lockArg.asset == address(0) ? _lockArg.totalAmount : 0
            );
        }

        uint256 lockId = locks[_lockArg.platform].length;

        address holder = _createUserHolder(_lockArg.receiver);
        uint256 netAmount = _transferAsset(
            _lockArg.asset,
            holder,
            _lockArg.totalAmount
        );
        if (!_lockArg.allowTax) {
            require(
                netAmount == _lockArg.totalAmount,
                "CryptohubLock: TAX_NOT_ALLOWED"
            );
        }

        locks[_lockArg.platform].push(
            LockData({
                asset: _lockArg.asset,
                receiver: _lockArg.receiver,
                holder: holder,
                vestingStart: _lockArg.vestingStart,
                firstUnlockRatio: _lockArg.firstUnlockRatio,
                unlockInterval: _lockArg.unlockInterval,
                lockDuration: _lockArg.lockDuration,
                totalAmount: _lockArg.totalAmount,
                amountWithdrawn: 0
            })
        );

        emit LockCreated(_lockArg.platform, lockId, _lockArg.reason);
    }

    function _createUserHolder(address _receiver) internal returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_receiver));
        address holder = LockHolderUtils.predictLockAddress(
            address(this),
            lockHolderImplementation,
            _receiver
        );
        // check if holder already exists
        if (userHolders[holder] != address(0)) {
            return holder;
        } else {
            holder = ClonesUpgradeable.cloneDeterministic(
                lockHolderImplementation,
                _salt
            );
            userHolders[holder] = _receiver;
            return holder;
        }
    }

    function createUserHolder(address _receiver) external returns (address) {
        return _createUserHolder(_receiver);
    }

    function predictLockHolderAddress(
        address _receiver
    ) external view returns (address) {
        bytes32 _salt = keccak256(abi.encodePacked(_receiver));

        return
            ClonesUpgradeable.predictDeterministicAddress(
                lockHolderImplementation,
                _salt,
                address(this)
            );
    }

    /**
     * @notice Adds more tokens to a lock
     * @param _platform  Platform ID
     * @param _lockId  Lock ID
     * @param _amount  Amount to increase
     */
    function increaseAmountForLock(
        uint256 _platform,
        uint256 _lockId,
        uint256 _amount
    ) external payable {
        LockData storage _lock = locks[_platform][_lockId];

        uint256 netAmount = _transferAsset(_lock.asset, _lock.holder, _amount);
        _lock.totalAmount += uint192(netAmount);

        emit LockAmountUpdated(_platform, _lockId, _lock.totalAmount);
    }

    event ClaimedUnlockedToken(
        uint256 indexed _platform,
        uint256 lockId,
        uint256 amount
    );

    function claimUnlockedToken(uint256 _platform, uint256 _lockId) external {
        LockData memory _lock = locks[_platform][_lockId];
        require(msg.sender == _lock.receiver, "CryptohubLock: UNAUTHORIZED");

        uint256 unlockedAmount = getUnlockedAmount(_lock);

        require(
            unlockedAmount > _lock.amountWithdrawn,
            "CryptohubLock: NOTHING_TO_CLAIM"
        );

        uint256 amountToTransfer = unlockedAmount - _lock.amountWithdrawn;

        locks[_platform][_lockId].amountWithdrawn = uint192(unlockedAmount);

        ILockHolder(_lock.holder).transfer(
            _lock.asset,
            _lock.receiver,
            amountToTransfer
        );

        emit ClaimedUnlockedToken(_platform, _lockId, amountToTransfer);
    }

    function getFullLock(
        uint256 _platform,
        uint256 _lockId
    ) external view returns (FullLock memory) {
        LockData memory _lock = locks[_platform][_lockId];
        return _getFullLock(_lock);
    }

    function getUnlockedAmount(
        LockData memory _lock
    ) public view returns (uint256 unlockedAmount) {
        if (block.timestamp < _lock.vestingStart) {
            return 0;
        }
        uint256 timePassed;
        unchecked {
            timePassed = block.timestamp - _lock.vestingStart;
        }
        if (timePassed >= _lock.lockDuration) {
            unlockedAmount = _lock.totalAmount;
        } else {
            uint256 firstUnlockAmount = (_lock.totalAmount *
                _lock.firstUnlockRatio) / RATIOS_PRECISION;

            uint256 vestedAmount = _lock.totalAmount - firstUnlockAmount;

            uint256 intervalCounts = timePassed / _lock.unlockInterval;
            uint256 totalIntervals = _lock.lockDuration / _lock.unlockInterval;
            if (_lock.lockDuration % _lock.unlockInterval != 0) {
                // add one more interval if there is a remainder to prevent unlocking everything before the lock ends
                totalIntervals++;
            }

            unlockedAmount =
                firstUnlockAmount +
                ((vestedAmount * intervalCounts) / totalIntervals);
        }
    }

    function _getFullLock(
        LockData memory _lock
    ) internal view returns (FullLock memory) {
        uint256 unlockedAmount = getUnlockedAmount(_lock);

        return
            FullLock({
                asset: _lock.asset,
                receiver: _lock.receiver,
                holder: _lock.holder,
                vestingStart: _lock.vestingStart,
                firstUnlockRatio: _lock.firstUnlockRatio,
                unlockInterval: _lock.unlockInterval,
                lockDuration: _lock.lockDuration,
                totalAmount: _lock.totalAmount,
                amountWithdrawn: _lock.amountWithdrawn,
                unlockedAmount: unlockedAmount,
                amountAvailable: unlockedAmount - _lock.amountWithdrawn
            });
    }

    function _transferAsset(
        address _asset,
        address _receiver,
        uint256 _amount
    ) internal returns (uint256 netTransfer) {
        netTransfer = _amount;
        if (_asset == address(0)) {
            require(msg.value >= _amount, "CryptohubLock: ETH_AMOUNT_MISMATCH");
            (bool success, ) = _receiver.call{value: _amount}("");
            require(success, "CryptohubLock: ETH_TRANSFER_FAILED");
        } else {
            uint256 balanceBefore = IERC20Upgradeable(_asset).balanceOf(
                _receiver
            );
            IERC20Upgradeable(_asset).safeTransferFrom(
                msg.sender,
                _receiver,
                _amount
            );
            netTransfer =
                IERC20Upgradeable(_asset).balanceOf(_receiver) -
                balanceBefore;
        }
    }

    function locksLength(uint256 _platform) external view returns (uint256) {
        return locks[_platform].length;
    }

    function holderOwner(address _holder) external view returns (address) {
        return userHolders[_holder];
    }

    uint256[50] private __CryptohubLock__gap;
}

// 
contract CryptohubLockFactoryUpgradable is
    LockerFactoryStorageUpgradable,
    UUPSUpgradeable
{
    function initialize(
        uint256[] memory _cryptohubCommissionArg,
        address _treasuryArg,
        address[] memory _adminsArg,
        address[] memory _platformReceivers,
        Price[] memory _baseFeesArg,
        Price[][] memory _platformFees
    ) public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __Ownable_init();

        __CryptohubLock_init(
            _adminsArg,
            _treasuryArg,
            _cryptohubCommissionArg,
            _baseFeesArg,
            _platformReceivers,
            _platformFees
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}