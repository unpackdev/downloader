// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

contract EthConnectorStorage {
    
    uint constant public ONE_HUNDRED_PERCENT = 10000;
    address constant public ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // ^ Native token representative

    address public across;
    address public polyConnector;
    uint public sourceChainId;
    uint public targetChainId;
    address public wrappedNativeToken;
    uint public msgIndx;

    // This mapping specifies the min biding amount for each token
    mapping(address => uint) public minAmounts;

    // Initial value is 10000 (owner can change it) 
    uint public minModifier;
}