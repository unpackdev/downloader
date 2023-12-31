// solution for curta challenge :D 

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
contract SuperFoo {
    fallback() external payable {
        assembly {
            mstore(0x00, 0x00)
            return(0x00, 0x20)
        }
    }
}