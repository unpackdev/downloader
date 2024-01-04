// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ISablier.sol"; // copied from proposal 28


contract Proposal {
    address constant me = 0xeb3E49Af2aB5D5D0f83A9289cF5a34d9e1f6C5b4;
    address constant torn = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;
    address constant sablier = 0xCD18eAa163733Da39c232722cBC4E8940b1D8888; 
    uint256 constant quarterDuration = 91 days; 
    uint256 constant remunerationAmount =  16666 ether;

    function executeProposal() external {
        // from proposal 28
        uint256 remunerationNormalizedAmount = remunerationAmount - (remunerationAmount % quarterDuration);
        uint256 remunerationPeriodStart = block.timestamp;

        IERC20(torn).approve(sablier, remunerationNormalizedAmount);

        ISablier(sablier).createStream(
            me,
            remunerationNormalizedAmount,
            torn,
            remunerationPeriodStart,
            remunerationPeriodStart + quarterDuration
        );
    }
}
