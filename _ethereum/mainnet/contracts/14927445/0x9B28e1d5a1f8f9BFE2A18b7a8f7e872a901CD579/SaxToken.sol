//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./WhiteListable.sol";
import "./Restrictable.sol";
import "./ERC1404.sol";

contract SaxToken is ERC1404, WhiteListable, Restrictable {

    // Token Details
    string constant TOKEN_NAME = "SAX";
    string constant TOKEN_SYMBOL = "SAX";
    uint8 constant TOKEN_DECIMALS = 18;

    // Token supply - 1 Million Tokens, with 18 decimal precision
    uint256 constant MILLION = 100000000;
    uint256 constant TOKEN_SUPPLY = MILLION * (10 ** uint256(TOKEN_DECIMALS));

    // ERC1404 Error codes and messages
    uint8 public constant SUCCESS_CODE = 0;
    uint8 public constant FAILURE_NON_WHITELIST = 1;
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    string public constant FAILURE_NON_WHITELIST_MESSAGE = "The transfer was restricted due to white list configuration.";
    string public constant UNKNOWN_ERROR = "Unknown Error Code";


    /**
    Constructor for the token to set readable details and mint all tokens
    to the contract creator.
     */
    constructor(address owner)
        ERC20(TOKEN_NAME, TOKEN_SYMBOL)
    {		
        _transferOwnership(owner);
        _mint(owner, TOKEN_SUPPLY);
    }

    /**
    This function detects whether a transfer should be restricted and not allowed.
    If the function returns SUCCESS_CODE (0) then it should be allowed.
     */
    function detectTransferRestriction (address from, address to, uint256)
        public
        override
        view
        returns (uint8)
    {               
        // If the restrictions have been disabled by the owner, then just return success
        // Logic defined in Restrictable parent class
        if(!isRestrictionEnabled()) {
            return SUCCESS_CODE;
        }

        // If the contract owner is transferring, then ignore reistrictions        
        if(from == owner()) {
            return SUCCESS_CODE;
        }

        // Restrictions are enabled, so verify the whitelist config allows the transfer.
        // Logic defined in Whitelistable parent class
        if(!checkWhitelistAllowed(from, to)) {
            return FAILURE_NON_WHITELIST;
        }

        // If no restrictions were triggered return success
        return SUCCESS_CODE;
    }
    
    /**
    This function allows a wallet or other client to get a human readable string to show
    a user if a transfer was restricted.  It should return enough information for the user
    to know why it failed.
     */
    function messageForTransferRestriction (uint8 restrictionCode)
        public
        override
        pure
        returns (string memory)
    {
        if (restrictionCode == SUCCESS_CODE) {
            return SUCCESS_MESSAGE;
        }

        if (restrictionCode == FAILURE_NON_WHITELIST) {
            return FAILURE_NON_WHITELIST_MESSAGE;
        }

        // An unknown error code was passed in.
        return UNKNOWN_ERROR;
    }

    /**
    Evaluates whether a transfer should be allowed or not.
     */
    modifier notRestricted (address from, address to, uint256 value) {        
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    /**
    Overrides the parent class token transfer function to enforce restrictions.
     */
    function transfer (address to, uint256 value)
        public
        override
        notRestricted(msg.sender, to, value)
        returns (bool success)
    {
        success = super.transfer(to, value);
    }

    /**
    Overrides the parent class token transferFrom function to enforce restrictions.
     */
    function transferFrom (address from, address to, uint256 value)
        public
        override
        notRestricted(from, to, value)
        returns (bool success)
    {
        success = super.transferFrom(from, to, value);
    }
}
