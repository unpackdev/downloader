// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnerBalance.sol";

/**
 * @title Allows allocating portion of the contract's funds to the owner balance
 */
abstract contract OwnerBalanceContributor {

    // OwnerBalance contract address
    address public immutable ownerBalanceAddress;

    uint public ownerBalanceDeposits;

    /**
     * @param _ownerBalanceAddress Address of the OwnerBalance contract
     */
    constructor (address _ownerBalanceAddress) {
        ownerBalanceAddress = _ownerBalanceAddress;
    }

    /**
     * @dev Assigns given amount of contract funds to the owner's balance
     * @param amount Amount in wei
     */
    function _transferToOwnerBalance(uint amount) internal {
        ownerBalanceDeposits += amount;
    }

    /**
     * @dev Allows OwnerBalance contract to withdraw deposits
     * @param ownerAddress Owner address to send funds to
     *
     * Requirements:
     * - caller must be the OwnerBalance contract
     */
    function withdrawOwnerBalanceDeposits(address ownerAddress) external {
        require(msg.sender == ownerBalanceAddress, 'Caller must be the OwnerBalance contract');
        uint currentBalance = ownerBalanceDeposits;
        ownerBalanceDeposits = 0;
        payable(ownerAddress).transfer(currentBalance);
    }
}
