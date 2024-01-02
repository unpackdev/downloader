// SPDX-License-Identifier: NONE

pragma solidity ^0.8.18;

contract TokenEvents {
    //when a user stakes tokens
    event TokenStake(address indexed user, uint value);

    //when a user unstakes tokens
    event TokenUnstake(address indexed user, uint value);

    //when a user unstakes tokens
    event EmergencyTokenUnstake(address indexed user, uint value, uint fee);

    //when a user burns tokens
    event TokenBurn(address indexed user, uint value);

    //when swapTokensForEth fails
    event SwapFailed(uint256 amount);

    //when autoBurLpTokens fails
    event AutoBurnFailed(uint256 amount);
}
