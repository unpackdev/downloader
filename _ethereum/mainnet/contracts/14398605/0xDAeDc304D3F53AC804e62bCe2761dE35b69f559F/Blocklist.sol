// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//import "./console.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";



/// @title Blocklist
/// @notice This contract can be used to maintain a blocklist
/// Blocklist includes:
/// - EVM Addresses from OFAC SDN and Blocked Persons List
contract Blocklist is AccessControl {
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet internal _blocklist;

    constructor(address[] memory startingBlockedAddresses) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MAINTAINER_ROLE, msg.sender);

        _addToBlocklist(startingBlockedAddresses);
    }

    event Blocked(address[] addresses);
    event UnBlocked(address[] addresses);


    /**
     * @dev Returns true if user is NOT on the blocklist otherwise returns false
     */
    function isNotBlocked(address _address) external view returns(bool) {
        return _blocklist.contains(_address) != true;
    }

    /**
     * @dev Returns array of addresses that are blocked
     * WARNING: Use as view function only, not for state-changing functions.
     * see EnumerableSet.values for more details on the warning above
     */
    function getBlocklist() external view returns (address[] memory recipients) {
        return _blocklist.values();
    }


    /**
     * @dev Add array of addresses to the blocklist
     *
     * Returns true if any address in the array were added to the blocklist
     */
    function addToBlocklist(address[] calldata _addresses) external onlyRole(MAINTAINER_ROLE) returns(bool) {
        return _addToBlocklist(_addresses);
    }

    /**
     * @dev Remove array of addresses from the blocklist
     *
     * Returns true if any address in the array was removed from blocklist
     */
    function removeFromBlocklist(address[] calldata _addresses) external onlyRole(MAINTAINER_ROLE) returns(bool) {
        return _removeFromBlocklist(_addresses);
    }


    /**
     * @dev Internal function to add array of addresses to the blocklist
     * _addresses needs to be of memory to support its use in the constructor
     * Returns true if any address in the array were added to the blocklist
     */
    function _addToBlocklist(address[] memory _addresses) internal returns(bool){
        bool didAdd = false;
        uint arrayLen = _addresses.length;
        for (uint256 i = 0; i < arrayLen; i++) {
            bool added = _blocklist.add(_addresses[i]);
            if (didAdd == false && added == true) {
                didAdd = true;
            }
        }
        emit Blocked(_addresses);
        return didAdd;
    }

    /**
     * @dev Internal function to remove array of addresses from the blocklist
     *
     * Returns true if any address in the array was removed from blocklist
     */
    function _removeFromBlocklist(address[] calldata _addresses) internal returns(bool){
        bool didRemove = false;
        uint arrayLen = _addresses.length;
        for (uint256 i = 0; i < arrayLen; i++) {
            bool removed = _blocklist.remove(_addresses[i]);
            if (didRemove == false && removed == true) {
                didRemove = true;
            }
        }
        return didRemove;
    }
}
