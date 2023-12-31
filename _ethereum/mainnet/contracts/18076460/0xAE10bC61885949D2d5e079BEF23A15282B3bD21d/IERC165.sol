// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC165 {

    /**
        @dev Checks if the smart contract includes a specific interface. This function uses less than 30,000 gas.
        @param _interfaceID The interface identifier, as specified in ERC-165.
        @return True if _interfaceID is supported, false otherwise.
    */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
