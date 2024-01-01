// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IERC20.sol";
import "./IAntfarmPosition.sol";

interface Igovernor {
    function getVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
}

interface IAntfarming {
    function currentRewards(uint256 positionId)
        external
        view
        returns (uint256 amount);
}

contract AntfarmGuild {
    address public immutable antfarmPositions;
    address public immutable antfarming;
    address public immutable governor;
    address public immutable veAGT;

    constructor(
        address _antfarmPositions,
        address _antfarming,
        address _governor,
        address _veAGT
    ) {
        require(_antfarmPositions != address(0));
        antfarmPositions = _antfarmPositions;
        antfarming = _antfarming;
        governor = _governor;
        veAGT = _veAGT;
    }

    function checkAntvocateRole(address user)
        public
        view
        returns (uint256, uint256)
    {
        uint256 lastBlock = block.number - 1;
        uint256 votingPower = Igovernor(governor).getVotes(user, lastBlock);
        uint256 veAGTBalance = IERC20(veAGT).balanceOf(user);

        uint256 delegated = votingPower - veAGTBalance;

        return (delegated, votingPower);
    }

    function checkHoneyPotRole(address user) public view returns (uint256) {
        IAntfarmPosition ipos = IAntfarmPosition(antfarmPositions);
        uint256[] memory positionIds = ipos.getPositionsIds(user);
        IAntfarmPosition.PositionDetails[] memory posDetails = ipos
            .getPositionsDetails(positionIds);

        uint256 cumulatedAtf;
        for (uint256 i = 0; i < posDetails.length; i++) {
            cumulatedAtf +=
                posDetails[i].cumulatedDividend +
                posDetails[i].dividend;
        }

        uint256[] memory farmingPositionIds = ipos.getPositionsIds(antfarming);
        IAntfarmPosition.PositionDetails[] memory farmingPosDetails = ipos
            .getPositionsDetails(farmingPositionIds);

        for (uint256 i = 0; i < farmingPosDetails.length; i++) {
            if (
                farmingPosDetails[i].delegate == user &&
                farmingPosDetails[i].owner == antfarming
            ) {
                cumulatedAtf +=
                    farmingPosDetails[i].cumulatedDividend +
                    farmingPosDetails[i].dividend;
            }
        }

        return cumulatedAtf;
    }

    function checkAntfarmingRole(address user) public view returns (uint256) {
        IAntfarmPosition ipos = IAntfarmPosition(antfarmPositions);
        uint256[] memory farmingPositionIds = ipos.getPositionsIds(antfarming);
        IAntfarmPosition.PositionDetails[] memory farmingPosDetails = ipos
            .getPositionsDetails(farmingPositionIds);

        uint256 userHasFarming;
        for (uint256 i = 0; i < farmingPosDetails.length; i++) {
            if (
                farmingPosDetails[i].delegate == user &&
                farmingPosDetails[i].owner == antfarming
            ) {
                userHasFarming += 1;
            }
        }

        return userHasFarming;
    }
}
