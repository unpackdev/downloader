// SPDX-License-Identifier: MIT

/**
 * @title bahia base contract
*/

pragma solidity ^0.8.4;

error NotDev();
error NotAllowed();

contract Bahia
{
    address public devAddress;
    uint256 public devRoyalty;  // out of 100,000

    // allow certain contracts
    mapping(address => bool) internal allowedContracts;

    constructor (uint256 devRoyalty_)
    {
        // set the dev royalty
        devRoyalty = devRoyalty_;

        // set the dev address to that in the constructor
        devAddress = msg.sender;
    }

    /**
     * @notice a modifier to mark functions that only the dev can touch
    */
    modifier onlyDev()
    {
        if (tx.origin != devAddress) revert NotDev();
        _;
    }

    /**
     * @notice a modified that only allowed contracts can access
    */
    modifier onlyAllowed()
    {
        if (!allowedContracts[msg.sender]) revert NotAllowed();
        _;
    }

    /**
     * @notice allow the devs to change their address
     * @param devAddress_ for the new dev address
    */
    function changeDevAddress(address devAddress_) external onlyDev
    {
        devAddress = devAddress_;
    }

    /**
     * @notice allow the devs to change their royalty
     * @param devRoyalty_ for the new royalty
    */
    function changeDevRoyalty(uint256 devRoyalty_) external onlyDev
    {
        devRoyalty = devRoyalty_;
    }
}
