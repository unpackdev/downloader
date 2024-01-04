// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract DestinationChainBridgeStorage {

    address public oracleAddress;
    uint256 public feePercentage; // 100 = 1% / 10000 = 100%
    bool public isPaused;

    struct Bridge {
        uint256 id;
        uint256 chainId;
        uint256 amount;
        uint256 createDate;
        address user;
        address tokenAddress;
        string crossChainId;
        bool isCompleted;
    }

    mapping(address => bool)public allowedBridgeTokens; // token => allowed
    mapping(uint256 => bool) public allowedChains; // chainId => allowed
    mapping(address => mapping(address => uint256[])) public userBridgeIdsPerToken; // user => token => bridgeIds
    mapping(address => uint256[]) public allBridgesPerToken; // token => bridgeIds
    Bridge[] public allBridges;
    mapping(string => bool) public executedBridgingCrossChainIds;
}
