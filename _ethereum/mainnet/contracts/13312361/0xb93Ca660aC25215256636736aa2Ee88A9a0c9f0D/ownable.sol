// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ownable  {
    string constant OWNABLE_CALL_IS_NOT_THE_OWNER = "001001";
    string constant OWNABLE_NEW_OWNER_IS_ZERO = "001002";

    address private Manageowner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        Manageowner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getManageOwner() public view  returns (address) {
        return Manageowner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(Manageowner == msg.sender, OWNABLE_CALL_IS_NOT_THE_OWNER);
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public  onlyOwner {
        require(_newOwner != address(0), OWNABLE_NEW_OWNER_IS_ZERO);
        Manageowner = _newOwner;
    }
}