// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC165.sol";
contract InterfaceChecker {
    function checkInterfaces(address contractAddress, bytes4[] calldata interfaceIds) public view returns (bool) {
        uint i = 0;
        bool matchingInterfaceFound = false;
        ERC165 checkAddress = ERC165(contractAddress);
        for(i = 0; i < interfaceIds.length; i++) {
            if (checkAddress.supportsInterface(interfaceIds[i])) {
                matchingInterfaceFound = true;
                break;
            }
        }
        return matchingInterfaceFound;
    }
}
