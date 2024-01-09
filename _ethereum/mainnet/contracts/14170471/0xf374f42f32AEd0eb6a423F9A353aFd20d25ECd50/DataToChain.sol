// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SignatureChecker.sol";
import "./ECDSA.sol";

contract DataToChain {
    
    struct UserInfo {
        uint256 userId;
        uint256 parentId;
        uint256 lockeBalance;
        uint256 assetsBalance;
        uint256 changeBalance;
    }
    address public owner = msg.sender;

    mapping(address => UserInfo) public userInfos;

    mapping(uint256 => address) public userIdMapAddress;


    // Stores a new value in the contract
    function store(uint256 userId,uint256 parentId,uint256 lockeBalance,uint256 assetsBalance,uint256 changeBalance,bytes memory signature) public {
        require(userId != 0,"DataToChain: userId cannt be zero");
        require(userIdMapAddress[userId] == address(0),"DataToChain:userId Have imported");
        require(userInfos[msg.sender].userId == 0,"DataToChain: msg.sender Have imported");
        
        require(lockeBalance+assetsBalance+changeBalance>0,"DataToChain: The upload amount must be greater than 0");


        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, userId, parentId, lockeBalance, assetsBalance, changeBalance, this))); 
        require(SignatureChecker.isValidSignatureNow(owner, message, signature),"DataToChain: Signature verification failure");

        userIdMapAddress[userId] = msg.sender;
        
        userInfos[userIdMapAddress[userId]].userId = userId;
        userInfos[userIdMapAddress[userId]].parentId = parentId;
        userInfos[userIdMapAddress[userId]].lockeBalance = lockeBalance;
        userInfos[userIdMapAddress[userId]].assetsBalance = assetsBalance;
        userInfos[userIdMapAddress[userId]].changeBalance = changeBalance;

    }

    // Reads the last stored value
    function getParentAddress(address  userAddress) public view returns (address) {
        return userIdMapAddress[userInfos[userAddress].parentId];
    }

    // Reads the last stored value
    function getUpChainAmount(address  userAddress) public view returns (uint256) {
        return userInfos[userAddress].lockeBalance+userInfos[userAddress].assetsBalance+userInfos[userAddress].changeBalance;
    }

    // Reads the last stored value
    function isUp(address  userAddress,uint256 userId) public view returns (bool,bool) {
        bool addressBool = userInfos[userAddress].userId > 0;
        bool userIdBool = userIdMapAddress[userId] != address(0);
        return (addressBool,userIdBool);
    }
}