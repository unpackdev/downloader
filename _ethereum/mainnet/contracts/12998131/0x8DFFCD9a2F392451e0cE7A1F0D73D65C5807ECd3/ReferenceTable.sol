pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
import "./Ownable.sol";

pragma experimental ABIEncoderV2;

contract ReferenceTable is Ownable{
    mapping (address => string) private _address_reference;
    mapping (string => address) private _reference_address;
    mapping (address => bool) private _address_reference_set;
    mapping (string => bool) private _reference_address_set;

    /**
     * @notice Sets iban associated to contract
     * @param _reference the reference
     */
    function setReference(string memory _reference) public virtual {
        require(_reference_address_set[_reference] != true, "Reference: already used");
        require(_address_reference_set[msg.sender] != true, "Reference: already set for this address");
        // check balance
        // if ( msg.sender.balance == 0 ){
        //     // If balance is 0 send him some token and return false
        //     // Send balance
        //     return false
        // }
        // else{

        // }
        // If balance is non 0 procced
        _address_reference_set[msg.sender] = true;
        _reference_address_set[_reference] = true;
        _address_reference[msg.sender] = _reference;
        _reference_address[_reference] = msg.sender;
    }

    /**
     * @notice Get the current reference
     */
    function getCurrentReference() public view returns (string memory) {
        return _address_reference[msg.sender];
    }

    /**
     * @notice Get the reference associated to an address
     */
    function getReferenceByAddress(address _address) public view onlyOwner returns (string memory) {
        return _address_reference[_address];
    }

    /**
     * @notice Get the address of a given reference
     */
    function getAddressByReference(string memory _reference) public view onlyOwner returns (address) {
        return _reference_address[_reference];
    }

}