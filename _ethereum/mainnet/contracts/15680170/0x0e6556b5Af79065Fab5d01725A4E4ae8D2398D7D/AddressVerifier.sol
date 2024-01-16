// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title AddressVerifier
 * @author NeatFi
 */
contract AddressVerifier {
    /**
     * Checks if a contract address exists.
     * @dev Loops over the array of token hashes of an Order.
     * @param addressToVerify - address of the contract in question.
     * @return bool check result.
     */
    function isValidContractAddress(address addressToVerify)
        internal
        view
        returns (bool)
    {
        uint256 addressSize;

        assembly {
            addressSize := extcodesize(addressToVerify)
        }

        require(
            addressSize > 0,
            "AddressVerifier::_isValidContractAddress: invalid contract address."
        );

        return true;
    }
}
