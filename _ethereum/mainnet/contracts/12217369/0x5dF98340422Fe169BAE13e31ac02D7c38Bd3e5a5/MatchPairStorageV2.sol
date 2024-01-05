// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./IUniswapV2Pair.sol";

import "./IStakeGatling.sol";
import "./IMatchPair.sol";
import "./IPriceSafeChecker.sol";

contract MatchPairStorageV2{
    uint256 public constant PROXY_INDEX = 3;
    IUniswapV2Pair public lpToken;
    IStakeGatling public stakeGatling;
    IPriceSafeChecker public priceChecker;
    //migrate via factory
    // IUniswapV2Factory public factoryAddress;

    struct UserInfo{
        address user;
        uint256 tokenPoint;
    }
    
    uint256 public pendingToken0;
    uint256 public pendingToken1;
    uint256 public totalTokenPoint0;
    uint256 public totalTokenPoint1;
    // in UniswapV2.burn() call ,small LP cause Exception('UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED')
    uint256 public sentinelAmount = 500;
    // filter too small asset, saving gas
    uint256 public minMintToken0;
    uint256 public minMintToken1;
    
    mapping(address => UserInfo) userInfo0;
    mapping(address => UserInfo) userInfo1;

    event Stake(bool _index0, address _user, uint256 _amount);

}
