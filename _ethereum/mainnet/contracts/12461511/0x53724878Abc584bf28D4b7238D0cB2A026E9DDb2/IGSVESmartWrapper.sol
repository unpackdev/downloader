// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @dev interface for v1 gsve smart wrapper
*/
interface  IGSVESmartWrapper{

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * also sets the GSVE token reference
     */
    function init (address initialOwner) external;

    /**
    * @dev allow the contract to recieve funds. 
    * This will be needed for dApps that check balances before enabling transaction creation.
    */
    receive() external payable;
    
    /**
    * @dev the wrapTransaction function interacts with other smart contracts on the users behalf
    * this wrapper works for any smart contract
    * as long as the dApp/smart contract the wrapper is interacting with has the correct approvals for balances within this wrapper
    * if the function requires a payment, this is handled too and sent from the wrapper balance.
    */
    function wrapTransaction(bytes calldata data, address contractAddress, uint256 value, address gasToken, uint256 tokenFreeValue, bool sender) external;
    
    /**
    * @dev function that the user can trigger to withdraw the entire balance of their wrapper back to themselves.
    */
    function withdrawBalance() external;

    /**
    * @dev function that the user can trigger to withdraw an entire token balance from the wrapper to themselves
    */
    function withdrawTokenBalance(address token) external;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

}
