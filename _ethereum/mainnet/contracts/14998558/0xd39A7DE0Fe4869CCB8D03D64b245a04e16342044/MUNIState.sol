// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

/*
    Inspired by https://github.com/gelatodigital/g-uni-v1-core/blob/master/contracts/GUniPool.sol#L135

    MUNI (Managed Uni)

    As of Uniswap V3, liquidity positions will be represented by an NFT.
    Managing LPs efficiently is within the protocols interest, such as
    concentrating liquidity between a certain range for like-minded pairs.

    MUNI will be responsible for managing said positions while issuing out a ERC20 token as a receipt
*/

import "./IUniswapV3.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";


contract MUNIState is
    OwnableUpgradeable,
    ERC20Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{    
    /***** Variables *****/

    /* !!!! Important !!!! */
    // Do _not_ change the layout of the variables
    // as you'll be changing the slots

    // Management fee and accounting
    uint16 public managerFeeBPS;
    uint256 public managerBalance0;
    uint256 public managerBalance1;

    // Management variables - slippages
    uint32 slippageInterval = 5 minutes;
    uint16 slippageBPS = 500; // 5%
    uint16 withdrawBPS = 100; // 1%
    uint16 rebalanceBPS = 200; // 2%

    int24 public lowerTick;
    int24 public upperTick;

    IUniswapV3Pool public pool;
    IERC20 public token0;
    IERC20 public token1;

    // Re-initialization guard
    bool isInitialized;

    function renounceOwnership() public pure override {
        revert("This feature is not available");
    }
}
