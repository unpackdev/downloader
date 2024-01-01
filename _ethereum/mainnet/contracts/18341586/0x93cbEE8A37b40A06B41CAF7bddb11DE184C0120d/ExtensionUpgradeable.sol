// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./StringsUpgradeable.sol";

contract ExtensionUpgradeable is Initializable {

    using StringsUpgradeable for uint256;

    mapping(bytes32 => bool) public initializedExtensions;

    modifier onlyInitializedExtension(bytes32 extension) {
        _checkInitialized(extension);
        _;
    }

    function initializeExtension(bytes32 extension) internal {
        if (initializedExtensions[extension]) {
            revert(string(abi.encodePacked("Extension: ", uint256(extension).toHexString(32), " already initialized.")));
        }
        initializedExtensions[extension] = true;
    }

    function _checkInitialized(bytes32 extension) internal view {
        if (!initializedExtensions[extension]) {
            revert(string(abi.encodePacked("Extension: ", uint256(extension).toHexString(32), " needs to be initialized.")));
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;

}