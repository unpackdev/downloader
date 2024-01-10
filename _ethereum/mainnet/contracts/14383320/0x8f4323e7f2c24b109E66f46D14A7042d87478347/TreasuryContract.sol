// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract DegenGangBeastsTreasury is Ownable {
    using SafeMath for uint256;
    
    address team1Address;
    address team2Address;
    address team3Address;

    constructor() {
        team1Address = 0xa55eE8375c38DEEA0173EdE54C39c2354b912A1B;
        team2Address = 0xd5a3383773a45dE394502092f17E9e4F50bf710A;
        team3Address = 0x5F058DCcffB7862566aBe44F85d409823F5ce921;
    }

    receive() external payable {}

    function setTeam1Address(address _team1Address) external onlyOwner {
        team1Address = _team1Address;
    }

    function setTeam2Address(address _team2Address) external onlyOwner {
        team2Address = _team2Address;
    }

    function setTeam3Address(address _team3Address) external onlyOwner {
        team3Address = _team3Address;
    }
    
    function withdrawErc20(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalBalance = token.balanceOf(address(this));
        uint256 team3Amount = totalBalance;

        uint256 team1Amount = (totalBalance * 4000) / 6000; // 4/6
        uint256 team2Amount = (totalBalance * 1000) / 6000; // 1/6
        team3Amount = team3Amount - team1Amount - team2Amount; // 1/6

        require(token.transfer(team1Address, team1Amount), "Withdraw failed to team 1.");

        require(token.transfer(team2Address, team2Amount), "Withdraw failed to team 2.");

        require(token.transfer(team3Address, team3Amount), "Withdraw failed to team 3.");
    }

    function withdrawETH() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 team3Amount = totalBalance;

        uint256 team1Amount = (totalBalance * 4000) / 6000; // 4/6
        uint256 team2Amount = (totalBalance * 1000) / 6000; // 1/6
        team3Amount = team3Amount - team1Amount - team2Amount; // 1/6

        (bool withdrawTeam1, ) = team1Address.call{value: team1Amount}("");
        require(withdrawTeam1, "Withdraw failed to team 1 address.");

        (bool withdrawTeam2, ) = team2Address.call{value: team2Amount}("");
        require(withdrawTeam2, "Withdraw failed to team 2 address.");

        (bool withdrawTeam3, ) = team3Address.call{value: team3Amount}("");
        require(withdrawTeam3, "Withdraw failed to team 3 address.");
    }
}
