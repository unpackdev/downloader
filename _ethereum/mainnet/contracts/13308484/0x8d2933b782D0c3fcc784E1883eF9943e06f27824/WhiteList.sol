// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

// Whitelist smart contract
// This smart contract keeps list of addresses to whitelist
contract WhiteList is Ownable {
    mapping(address => bool) public whiteList;
    uint public totalWhiteListed; //white listed users number

    event LogWhiteListed(address indexed user, uint whiteListedNum);
    event LogRemoveWhiteListed(address indexed user);

    // @notice it will return status of white listing
    // @return true if user is white listed and false if is not
    function isWhiteListed(address _user) public view virtual returns (bool) {
        return whiteList[_user];
    }

    modifier onlyWhiteListed(address _user) {
        require(isWhiteListed(_user), "Whitelist: the address is not whitelisted");
        _;
    }

    // @notice it will remove whitelisted user
    // @param _contributor {address} of user to unwhitelist
    function removeFromWhiteList(address _user) external onlyOwner() returns (bool) {
        require(whiteList[_user] == true);
        whiteList[_user] = false;
        totalWhiteListed--;
        emit LogRemoveWhiteListed(_user);
        return true;
    }

    // @notice it will white list one member
    // @param _user {address} of user to whitelist
    // @return true if successful
    function addToWhiteList(address _user) external onlyOwner()  returns (bool) {
        require(whiteList[_user] == false);
        whiteList[_user] = true;
        totalWhiteListed++;
        emit LogWhiteListed(_user, totalWhiteListed);
        return true;
    }
}
