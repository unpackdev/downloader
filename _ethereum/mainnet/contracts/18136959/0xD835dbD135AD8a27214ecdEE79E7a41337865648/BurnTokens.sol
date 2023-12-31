pragma solidity 0.8.18;

import "./Admin.sol";

/**
 * @title BurnTokens
 * @notice BurnTokens contract keeps track of supported burn tokens
 */
contract BurnTokens is Admin {
    // ============ Storage ============
    // Mapping of burn token to whether it is a supported burn token
    mapping(address => bool) public supportedBurnTokens;

    // ============ Events ============
    /**
     * @notice Emitted when a burn token is added
     * @param token address of the burn token
     */
    event BurnTokenAdded(address token);
    /**
     * @notice Emitted when a burn token is removed
     * @param token address of the burn token
     */
    event BurnTokenRemoved(address token);

    // Errors
    error AlreadySupportedBurnToken();
    error InvalidTokenAddress();
    error UnSupportedBurnToken();
   
    // ============ Constructor ============
    /**
     * @notice Initializes the contract
     * @param burnToken contract address of the initial burn token
     */
    constructor(address burnToken) {
        addSupportedBurnToken(burnToken);
    }

    // ============ External Functions ============
    /**
     * @notice Adds a supported burn token
     * @param token address of the token contract
     */
    function addSupportedBurnToken(address token) public onlyAdmin {
        if (isSupportedBurnToken(token)) {
            revert AlreadySupportedBurnToken();
        }

        if (token == address(0)) {
            revert InvalidTokenAddress();
        }

        supportedBurnTokens[token] = true;
        
        emit BurnTokenAdded(token);
    }

    /**
     * @notice Removes a supported burn token
     * @param token address of the token contract
     */
    function removeSupportedBurnToken(address token) public onlyAdmin {
        if (!isSupportedBurnToken(token)) {
            revert UnSupportedBurnToken();
        }
        supportedBurnTokens[token] = false;

        emit BurnTokenRemoved(token);
    }

    /**
     * @notice Returns whether a token is a supported burn token
     * @param token address of the token contract
     * @return bool true if token is a supported burn token
     */
    function isSupportedBurnToken(address token) public view returns (bool) {
        return supportedBurnTokens[token];
    }
}