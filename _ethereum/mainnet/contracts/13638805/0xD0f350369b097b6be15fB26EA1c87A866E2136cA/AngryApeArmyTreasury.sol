// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

contract AngryApeArmyTreasury is Ownable {
    using SafeMath for uint256;

    address public projectOwnersAddress;
    address public devAddress;

    constructor(address _projectOwnersAddress, address _devAddress) {
        projectOwnersAddress = _projectOwnersAddress;
        devAddress = _devAddress;
    }

    receive() external payable {}

    function withdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 restAmount = totalBalance;

        uint256 projectOwnersAmount = totalBalance.mul(9000).div(10000);
        uint256 devAmount = restAmount.sub(projectOwnersAmount);

        (bool withdrawProjectOwners, ) = projectOwnersAddress.call{value: projectOwnersAmount}("");
        require(withdrawProjectOwners, "Withdraw Failed To Project Owners.");

        (bool withdrawDev, ) = devAddress.call{value: devAmount}("");
        require(withdrawDev, "Withdraw Failed To Dev");
    }
}