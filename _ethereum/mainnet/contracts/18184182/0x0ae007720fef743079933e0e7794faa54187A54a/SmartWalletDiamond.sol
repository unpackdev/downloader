// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDiamond{        
    function authSelectorToFacet(address owner, address msgSender, bytes4 fnSig) external view returns(address);
}

contract SmartWalletDiamond {
    
    /// @dev the main diamond to clone
    address public diamond;
    address public immutable owner;
    bool initialized;
    
    error InvalidFunction();
    error Unauthorized();
    error Initialized();

    constructor (address owner_){
        owner=owner_;
    }

    function initialize(address diamond_) public {
        if(initialized) revert Initialized();
        diamond=diamond_;
        initialized=true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        // get facet from function selector        
        
        address facet = IDiamond(diamond).authSelectorToFacet(owner, msg.sender, msg.sig);
        if (facet == address(0)) revert InvalidFunction();
        
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
