// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


interface IGTokenRewardManager {
    function setRewardPerBlock( uint256 rewardPerBlock ) external ;
    function getRewardPerBlock( ) external view returns (uint256 rewardPerBlock );

    function mint( uint256 curBlock, uint key, uint256 amount, address addr ) external;
    function burn( uint256 curBlock, uint key, uint256 amount, address addr ) external;
    function claim( uint key,  address addr ) external;
    function getReward( uint256 curBlock, uint key ) external view returns (uint256 reward );

}

interface IInterestManager {
    function setAnnualizedRate( uint256 interestPerYear ) external;
    function setInterestRate( uint256 interestPerBlock ) external;
    function getInterestRate( ) external view returns (uint256 interestPerBlock );

    function mint( uint256 curBlock, uint key, uint256 amount, address addr ) external;
    function burn( uint256 curBlock, uint key, uint256 amount, address addr ) external;
    function payInterest( uint256 curBlock, uint key, uint256 interest  ) external;
    function getInterest( uint256 curBlock, uint key ) external view returns( uint256 interest );

}

interface ILiquidationManager {
    function liquidate( uint256 vauldId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward )  payable external;
}

