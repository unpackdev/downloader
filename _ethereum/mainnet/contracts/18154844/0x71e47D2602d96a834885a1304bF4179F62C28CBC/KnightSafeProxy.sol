// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title KnightSafeProxy
 * @notice Using proxy design pattern to save gas consumption for distribution  
 */
contract KnightSafeProxy {
    
    // implementation address needs to be the first declared variable. 
    address internal implementation;

    /**
     * @notice Constructor function sets address of implementation contract.
     * @param _implementation Implementation address
     */
    constructor(address _implementation) {
        require(_implementation != address(0), "Implementation address should not be null.");
        implementation = _implementation;
    }

    /**
     * @notice Fallback function forwards all transactions and returns all received return data.
     */
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _implementation := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // copy msg.data.
            calldatacopy(0, 0, calldatasize())

            // call the implementation.
            let result  := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // copy the returned data.
            returndatacopy(0, 0, returndatasize())
            
            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
