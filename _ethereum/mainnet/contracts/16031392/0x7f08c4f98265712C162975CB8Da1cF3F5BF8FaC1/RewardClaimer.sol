// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./Ownable.sol";

import "./IChessSchedule.sol";
import "./IChessController.sol";
import "./CoreUtility.sol";
import "./SafeDecimalMath.sol";

contract RewardClaimer is Ownable, CoreUtility {
    using SafeDecimalMath for uint256;

    event ClaimerUpdated(address newClaimer);

    IChessSchedule public immutable chessSchedule;
    IChessController public immutable chessController;

    address public rewardClaimer;
    uint256 public lastWeek;

    constructor(address chessSchedule_, address chessController_) public {
        chessSchedule = IChessSchedule(chessSchedule_);
        chessController = IChessController(chessController_);
        lastWeek = _endOfWeek(block.timestamp);
    }

    function updateClaimer(address newClaimer) external onlyOwner {
        rewardClaimer = newClaimer;
        emit ClaimerUpdated(newClaimer);
    }

    modifier onlyClaimer() {
        require(msg.sender == rewardClaimer, "Only reward claimer");
        _;
    }

    function claimRewards() external onlyClaimer {
        uint256 amount = _checkpoint();
        chessSchedule.mint(msg.sender, amount);
    }

    function _checkpoint() private returns (uint256 amount) {
        uint256 w = lastWeek;
        uint256 currWeek = _endOfWeek(block.timestamp) - 1 weeks;

        for (; w < block.timestamp; w += 1 weeks) {
            uint256 weeklySupply = chessSchedule.getWeeklySupply(w);
            if (weeklySupply == 0) {
                // CHESS emission may update in the middle of a week due to cross-chain lag,
                // so we have to revisit the zero value as long as it is in the current week.
                if (w == currWeek) break;
                continue;
            }

            uint256 weeklyWeight = chessController.getFundRelativeWeight(address(this), w);
            if (weeklyWeight == 0) {
                continue;
            }

            amount = amount.add(weeklySupply.multiplyDecimal(weeklyWeight));
        }

        // Update global state
        lastWeek = w;
    }
}
