// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


///@title Interface for PLBTSTaking contract for DAO interactions
interface IPLBTStaking {

    ///@dev returns amount of staked tokens by user `_address`
    ///@param _address address of the user
    ///@return amount of tokens
    function getStakedTokens(address _address) external view returns (uint256);

    ///@dev sets reward for next distribution time
    ///@param _amountWETH amount of wETH tokens
    ///@param _amountWBTC amount of wBTC tokens
    function setReward(uint256 _amountWETH, uint256 _amountWBTC) external;

    ///@dev changes treasury address
    ///@param _treasury address of the treasury
    function changeTreasury(address _treasury) external;
}