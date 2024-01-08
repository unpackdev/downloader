// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <=0.7.6;

import "./Ownable.sol";

import "./MappedSinglyLinkedList.sol";

///@notice A registry to hold Contract addresses.  Underlying data structure is a singly linked list. 
contract AddressRegistry is Ownable {

    using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;

    MappedSinglyLinkedList.Mapping internal addressList;

    /// @notice Emmitted when a contract has been added to the registry
    event AddressAdded(address indexed _address);
    
    /// @notice Emmitted when a contract has been removed to the registry
    event AddressRemoved(address indexed _address);

    /// @notice Emitted when all the registry addresses are cleared
    event AllAddressesCleared();

    /// @notice Storage field for what type of contract this Registry is storing 
    string public addressType;    

    /// @notice Contract constructor sets addressType, intializes list and transfers ownership
    /// @param _addressType The type of contracts stored in this registry 
    /// @param _owner The address to set as owner of the contract
    constructor(string memory _addressType, address _owner) Ownable() {
        addressType = _addressType;
        addressList.initialize();
        transferOwnership(_owner);
    }

    /// @notice Returns an array of all contract addresses in the linked list
    /// @return Array of contract addresses
    function getAddresses() view external returns(address[] memory) {
        return addressList.addressArray();
    } 

    /// @notice Adds addresses to the linked list. Will revert if the address is already in the list.  Can only be called by the Registry owner.
    /// @param _addresses Array of contract addresses to be added
    function addAddresses(address[] calldata _addresses) public onlyOwner {
        for(uint256 _address = 0; _address < _addresses.length; _address++ ){
            addressList.addAddress(_addresses[_address]);
            emit AddressAdded(_addresses[_address]);
        }
    }

    /// @notice Removes an address from the linked list. Can only be called by the Registry owner.
    /// @param _previousContract The address positionally located before the address that will be deleted. This may be the SENTINEL address if the list contains one contract address
    /// @param _address The address to remove from the linked list. 
    function removeAddress(address _previousContract, address _address) public onlyOwner {
        addressList.removeAddress(_previousContract, _address); 
        emit AddressRemoved(_address);
    } 

    /// @notice Removes every address from the list
    function clearAll() public onlyOwner {
        addressList.clearAll();
        emit AllAddressesCleared();
    }
    
    /// @notice Determines whether the list contains the given address
    /// @param _addr The address to check
    /// @return True if the address is contained, false otherwise.
    function contains(address _addr) public returns (bool) {
        return addressList.contains(_addr);
    }

    /// @notice Gives the address at the start of the list
    /// @return The address at the start of the list
    function start() public view returns (address) {
        return addressList.addressMap[MappedSinglyLinkedList.SENTINEL];
    }

    /// @notice Exposes the internal next() iterator
    /// @param current The current address
    /// @return Returns the next address in the list
    function next(address current) public view returns (address) {
        return addressList.addressMap[current];
    }
    
    /// @notice Exposes the end of the list
    /// @return The sentinel address
    function end() public pure returns (address) {
        return MappedSinglyLinkedList.SENTINEL;
    }

}