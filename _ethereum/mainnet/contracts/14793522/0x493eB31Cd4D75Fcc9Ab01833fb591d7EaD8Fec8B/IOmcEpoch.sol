//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IOmcEpoch {
    event ReceipientModification(address indexed _receiver);
    event RoyaltyDistribution(address indexed _omcDistributor, uint256 _value);
    event SwapForWETH(address _token, uint256 _amountIn);
    event SwapETHForWETH(uint256 _amount);

    function setReceiver(address receiver) external;

    function setOmcDistributor(address omcDistributor) external;

    function setOmc(address omc) external;

    function setMiner(address miner) external;

    function setDistributeInterval(uint256 distributeInterval) external;

    function distribute() external;

    function swapTokenForWETH(address token) external;

    function swapETHForWETH() external;
}
