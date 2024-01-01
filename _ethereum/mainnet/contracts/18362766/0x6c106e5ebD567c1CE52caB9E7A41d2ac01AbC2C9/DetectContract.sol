// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MetaLend's DetectContract utility
 * @author MetaLend
 * @notice Contains function to detect if address is a contract
 * @dev Only works for already deployed contracts
 */
library DetectContract {
    /**
     * @notice function to detect if address is existing contract (already created)
     * @dev used for checking if caller is contract
     * @param addr the address of the account to check
     * @return bool if address is contract
     */
    function isExistingContract(address addr) internal view returns (bool) {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(addr)
        }
        if (contractSize == 0) {
            return false;
        } else {
            return true;
        }
    }
}
