// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

contract AngryApeArmyTreasury is Ownable {
    using SafeMath for uint256;
    
    address public teamMemberA;
    address public teamMemberB;
    address public teamMemberC;
    address public teamMemberD;
    address public teamMemberE;

    constructor() {
        teamMemberA = 0xD5144Af3d05C57Ba545e1B51A1769f4B4149d4dD;
        teamMemberB = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
        teamMemberC = 0x45f14c6F6649D1D4Cb3dD501811Ab7263285eaa3;
        teamMemberD = 0x672A7EC8fC186f6C9aa32d98C896821182907b08;
        teamMemberE = 0x5FA988805E792B6cA0466B2dbb52693b2DEfF33F;
    }

    receive() external payable {}

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 restAmount = totalBalance;

        uint256 teamMemberAAmount = totalBalance.mul(7000).div(10000); //70% | 5.25% of OpenSea resell
        restAmount = restAmount.sub(teamMemberAAmount);

        uint256 teamMemberBAmount = totalBalance.mul(2000).div(10000); //20% | 1.50% of OpenSea resell
        restAmount = restAmount.sub(teamMemberBAmount);

        uint256 teamMemberCAmount = totalBalance.mul(330).div(10000); //3.3% | 0.2475% of OpenSea resells
        restAmount = restAmount.sub(teamMemberCAmount);

        uint256 teamMemberDAmount = totalBalance.mul(330).div(10000); //3.3% | 0.2475% of OpenSea resells
        
        restAmount = restAmount.sub(teamMemberDAmount); //3.4% | 0.255% of OpenSea resells

        (bool withdrawTeamMemberA, ) = teamMemberA.call{value: teamMemberAAmount}("");
        require(withdrawTeamMemberA, "Withdraw Failed To Member A.");

        (bool withdrawTeamMemberB, ) = teamMemberB.call{value: teamMemberBAmount}("");
        require(withdrawTeamMemberB, "Withdraw Failed To Member B");

        (bool withdrawTeamMemberC, ) = teamMemberC.call{value: teamMemberCAmount}("");
        require(withdrawTeamMemberC, "Withdraw Failed To Member C");

        (bool withdrawTeamMemberD, ) = teamMemberD.call{value: teamMemberDAmount}("");
        require(withdrawTeamMemberD, "Withdraw Failed To Member D");
        
        (bool withdrawTeamMemberE, ) = teamMemberE.call{value: restAmount}("");
        require(withdrawTeamMemberE, "Withdraw Failed To Member E");
    }
}