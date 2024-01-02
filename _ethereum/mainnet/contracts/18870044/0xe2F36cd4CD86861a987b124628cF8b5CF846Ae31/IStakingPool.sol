// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingPool {
    // deposit Ether and receive Star tokens (1:1). Works exactly as ETH wrapping in WETH.deposit()
    function deposit() external payable;

    // convert Star tokens to the StakedStar tokens by current SStar rate
    function stake(
        uint256 starAmount
    ) external returns (uint256 stakedStarAmount);

    // call deposit then stake in one call
    function depositAndStake() external payable;

    // convert StakedStar tokens to Star tokens by current SStar rate
    function unstake(
        uint256 stakedStarAmount
    ) external returns (uint256 starAmount);

    // unwrap Star tokens to ETH (1:1). Ether do not send immediately, but put in withdrawal queue
    // when balance of the contract will have enough free ETH you can `claim` it
    function withdraw(uint256 starAmount) external;

    // unstake then withdraw in one call
    function unstakeAndWithdraw(uint256 stakedStarAmount) external;

    // Try to receive ETH already requested to withdraw
    function claim() external;

    // for small SStar amount make withdraw without enqueue/claim operations
    // more gas efficient and fast, but can't be used frequently and with big amounts
    function localPoolWithdraw(uint256 starAmount) external;

    // unstake then localPoolWithdraw in one call
    function unstakeAndLocalPoolWithdraw(uint256 stakedStarAmount) external;
}
