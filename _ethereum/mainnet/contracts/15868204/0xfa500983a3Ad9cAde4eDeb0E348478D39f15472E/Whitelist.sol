// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


import "./Base64.sol";
import "./Strings.sol";
import "./Layer.sol";

contract Whitelist{

    /// @notice Array of whitelisted users that are permitted to mint during Wave 1
    address [] public whitelistAddresses;
    address public admin;

    constructor(address[] memory _whitelistAddresses){
        whitelistAddresses = _whitelistAddresses;
        admin = msg.sender;
    }

    /// @notice Fetch the array of whitelisted users
    function addToWhiteList(address[] memory additionalWhiteListAddresses) external{
        require(msg.sender == admin, "No permission");
        for(uint i = 0; i < additionalWhiteListAddresses.length; i++) {
            whitelistAddresses.push(additionalWhiteListAddresses[i]);
        }
    }

    /// @notice Fetch the array of whitelisted users
    function getwhitelistArray() public view returns (address[] memory){
        return whitelistAddresses;
    }

    /// @notice Checks if an address is whitelisted
    /// @param userAddress Address to check
    function whitelistedAddresses(address userAddress)
    public
    view
    returns (bool)
    {
        bool isInArray;
        for(uint i = 0; i < whitelistAddresses.length; i++) {
            if(whitelistAddresses[i]==userAddress){
                isInArray=true;
                break;
            }
        }
        return isInArray;
    }
}