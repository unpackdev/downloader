// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./GenericErrors.sol";

/// @title Lib Allow List
/// @author FormalCrypto
/// @notice Provides functionalit to manage allowed contracts
library LibAllowList {
    bytes32 internal constant ALLOW_LIST_STORAGE = keccak256("allow.list.storage");

    struct AllowListStorage {
        mapping(bytes4 => bool) allowedSelector;
        mapping(address => bool) allowList;
        address[] contracts;
    }

    /**
     * @dev Fetch local storage
     */
    function _getStorage() internal pure returns (AllowListStorage storage als) {
        bytes32 position = ALLOW_LIST_STORAGE;
        assembly {
            als.slot := position
        }
    } 

    /**
     * Adds contract to allow list
     * @param _contract Address of the contract to be added
     */
    function addAllowedContract(address _contract) internal {
        isContract(_contract);

        AllowListStorage storage als = _getStorage();

        if (als.allowList[_contract]) return;

        als.allowList[_contract] = true;
        als.contracts.push(_contract);
    }

    /**
     * @dev Removes contract from allow list
     * @param _contract Address of the contract to be removed from allow list
     */
    function removeAllowedContract(address _contract) internal {
        AllowListStorage storage als = _getStorage();

        if (!als.allowList[_contract]) return;

        als.allowList[_contract] = false;

        uint256 contractListLength = als.contracts.length;

        for (uint256 i = 0; i < contractListLength;) {
            if (_contract == als.contracts[i]) {
                als.contracts[i] = als.contracts[contractListLength - 1];
                als.contracts.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Checks if contract added to allow list
     * @param _contract Address of the contract to be checked
     */
    function isContractAllowed(address _contract) internal view returns (bool) {
        return _getStorage().allowList[_contract];
    }

    /**
     * @dev Returns list of all contract added to allow list
     */
    function getAllAllowedContract() internal view returns (address[] memory) {
        return _getStorage().contracts;
    }

    /**
     * @dev Checks is the contract a contract
     * @param _contract Address of the contract to be checked
     */
    function isContract(address _contract) private view {
        if (_contract == address(0)) revert InvalidContract();
        if (_contract.code.length == 0) revert InvalidContract();
    }
}