// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract MartiansVSRednecksTreasury is Ownable {
    using SafeMath for uint256;
    
    address private teamAddress1;
    address private teamAddress2;
    address private teamAddress3;
    address private teamAddress4;
    address private netvrkAddress;
    address private devTeamAddress;

    modifier onlyDev() {
        require(devTeamAddress == _msgSender(), "MartiansVSRednecksTreasury::onlyDev: caller is not the dev.");
        _;
    }

    constructor() {
        netvrkAddress = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
        devTeamAddress = 0x71298E004c85e339C90390Df54e9265c4fF7b285;
        teamAddress1 = 0xaA9CB1fa773c3d36E79Ad39Ba116D8FF28344203;
        teamAddress2 = 0x9eA791D214aFE8FCb0257DC3e8fcf54C3AD35171;
        teamAddress3 = 0x3Bc057a2b4bb703FC5c02D2eAeDB63eD517F31DD;
        teamAddress4 = 0x49F2f8802531421873669Af560D99579fe243a21;
    }

    receive() external payable {}

    function setTeamAddress1(address _teamAddress1) external onlyOwner {
        teamAddress1 = _teamAddress1;
    }

    function setTeamAddress2(address _teamAddress2) external onlyOwner {
        teamAddress2 = _teamAddress2;
    }

    function setTeamAddress3(address _teamAddress3) external onlyOwner {
        teamAddress3 = _teamAddress3;
    }

    function setTeamAddress4(address _teamAddress4) external onlyOwner {
        teamAddress3 = _teamAddress4;
    }

    function setNetvrkAddress(address _netvrksAddress) external onlyOwner {
        netvrkAddress = _netvrksAddress;
    }

    function setDevTeamAddress(address _devTeamAddress) external onlyDev {
        devTeamAddress = _devTeamAddress;
    }
    
    function withdrawErc20(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalBalance = token.balanceOf(address(this));
        uint256 devTeamAmount = totalBalance;

        uint256 teamAmount = (totalBalance * 1750) / 10000;  // 17.5 for every team member
        uint256 netvrkAmount = (totalBalance * 2000) / 10000; // 20% for Netvrk
        devTeamAmount = devTeamAmount - (teamAmount * 4) - netvrkAmount; // resting 10% for dev team

        require(token.transfer(teamAddress1, teamAmount), "MartiansVSRednecksTreasury::withdrawErc20: Withdraw failed to team 1.");

        require(token.transfer(teamAddress2, teamAmount), "MartiansVSRednecksTreasury::withdrawErc20: Withdraw failed to team 2.");

        require(token.transfer(teamAddress3, teamAmount), "MartiansVSRednecksTreasury::withdrawErc20: Withdraw failed to team 3.");

        require(token.transfer(teamAddress4, teamAmount), "MartiansVSRednecksTreasury::withdrawErc20: Withdraw failed to team 4.");

        require(token.transfer(netvrkAddress, netvrkAmount), "MartiansVSRednecksTreasury::withdrawErc20: Withdraw failed to dev team.");

        require(token.transfer(devTeamAddress, devTeamAmount), "MartiansVSRednecksTreasury::withdrawErc20: Withdraw failed to netvrk.");
    }

    function withdrawETH() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 devTeamAmount = totalBalance;

        uint256 teamAmount = (totalBalance * 1750) / 10000;  // 17.5 for every team member
        uint256 netvrkAmount = (totalBalance * 2000) / 10000; // 20% for Netvrk
        devTeamAmount = devTeamAmount - (teamAmount * 4) - netvrkAmount; // resting 10% for dev team

        (bool withdrawTeam1, ) = teamAddress1.call{value: teamAmount}("");
        require(withdrawTeam1, "MartiansVSRednecksTreasury::withdrawETH: Withdraw failed to Team address 1.");

        (bool withdrawTeam2, ) = teamAddress2.call{value: teamAmount}("");
        require(withdrawTeam2, "MartiansVSRednecksTreasury::withdrawETH: Withdraw failed to Team address 2.");

        (bool withdrawTeam3, ) = teamAddress3.call{value: teamAmount}("");
        require(withdrawTeam3, "MartiansVSRednecksTreasury::withdrawETH: Withdraw failed to Team address 3.");

        (bool withdrawTeam4, ) = teamAddress4.call{value: teamAmount}("");
        require(withdrawTeam4, "MartiansVSRednecksTreasury::withdrawETH: Withdraw failed to Team address 4.");

        (bool withdrawNetvrk, ) = netvrkAddress.call{value: netvrkAmount}("");
        require(withdrawNetvrk, "MartiansVSRednecksTreasury::withdrawETH: Withdraw failed to Netvrk.");

        (bool withdrawDevTeam, ) = devTeamAddress.call{value: devTeamAmount}("");
        require(withdrawDevTeam, "MartiansVSRednecksTreasury::withdrawETH: Withdraw failed to dev team.");
    }
}
