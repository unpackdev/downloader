// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./SafeERC20Upgradeable.sol";
import "./IGuaranteedCompetitionContract.sol";
import "./RegularCompetitionContract.sol";

/*
GCC01: Exceed slot to bet
GCC02: Entrant invalid
GCC03: expired
GCC04: Not enough Fee
GCC05: Invalid length
GCC06: Invalid bracket
GCC07: Not enough Fee
GCC08: Bet time haven't finished yet
GCC09: Please waiting for end time and request data
*/

contract GuaranteedCompetitionContract is
    RegularCompetitionContract,
    IGuaranteedCompetitionContract
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public guaranteedFee;
    uint256 public maxEntrant;

    modifier onlySlotAvailable() {
        require(listBuyer.length < maxEntrant, "GCC01");
        _;
    }

    function setMaxEntrantAndGuaranteedFee(
        uint256 _guaranteedFee,
        uint256 _maxEntrant
    ) external override onlyConfigurator onlyLock {
        require(_maxEntrant > minEntrant, "GCC02");
        maxEntrant = _maxEntrant;
        guaranteedFee = _guaranteedFee;
    }

    function start()
        external
        override(RegularCompetitionContract, IRegularCompetitionContract)
        onlyOwner
        onlyLock
    {
        require(endBetTime >= block.timestamp, "GCC03");
        require(getTotalToken(tokenAddress) >= fee + guaranteedFee, "GCC04");
        totalFee = fee;
        status = Status.Open;
        emit Ready(block.timestamp, startBetTime, endBetTime);
    }

    function placeBet(address user, uint256[] memory betIndexs)
        external
        override
        onlyOpen
        betable(user)
        onlySlotAvailable
        onlyOwner
    {
        require(betIndexs.length == betOptions.length, "GCC05");
        for (uint256 i = 0; i < betIndexs.length; i++) {
            require(betIndexs[i] <= betOptions[i].brackets.length, "GCC06");
        }
        uint256 totalToken = getTotalToken(tokenAddress);
        uint256 totalEntryFee = listBuyer.length * entryFee;
        require(
            totalToken >=
                totalEntryFee + totalFee + fee + entryFee + guaranteedFee,
            "GCC07"
        );
        totalFee += fee;
        betOrNotYet[user] = true;
        listBuyer.push(user);
        bytes32 key = _generateKey(betIndexs);
        ticketSell[key].push(user);
        emit PlaceBet(user, betIndexs, entryFee + fee);
    }

    function distributedReward() external override onlyOpen nonReentrant {
        bool enoughEntrant = _checkEntrantCodition();

        address[] memory winners;
        uint256 ownerReward;
        uint256 creatorReward;
        uint256 winnerReward;
        uint256 totalEntryFee = listBuyer.length * entryFee;
        if (!enoughEntrant) {
            require(block.timestamp > endBetTime, "GCC08");
            status = Status.Non_Eligible;
            winners = listBuyer;
            winnerReward = totalEntryFee;
            creatorReward = guaranteedFee;
            ownerReward = totalFee;
        } else {
            (bytes32 key, bool success) = _getResult();
            if (!success) {
                uint256 maxTimeForRefunding = ICompetitionPool(owner)
                    .getMaxTimeWaitForRefunding();
                require(
                    block.timestamp > scheduledStartTime + maxTimeForRefunding,
                    "GCC09"
                );
                status = Status.Refund;
                winners = listBuyer;
                winnerReward = totalEntryFee + totalFee - fee;
                ownerReward = 0;
                creatorReward = fee + guaranteedFee;
            } else {
                status = Status.End;

                if (key != bytes32(0)) {
                    winners = ticketSell[key];
                } else {
                    winners = listBuyer;
                }

                if (guaranteedFee > 0) {
                    if (winners.length > 0) {
                        winnerReward = guaranteedFee;
                        ownerReward = totalFee;
                        creatorReward = totalEntryFee;
                    } else {
                        creatorReward = totalEntryFee;
                        ownerReward = totalFee + guaranteedFee;
                    }
                } else {
                    if (winners.length > 0) {
                        winnerReward = totalEntryFee;
                        ownerReward = totalFee;
                    } else {
                        ownerReward = totalFee + totalEntryFee;
                    }
                }
            }
        }

        competition.winnerReward = winnerReward;

        if (ownerReward > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, ownerReward);
        }
        if (creatorReward > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(creator, creatorReward);
        }
        if (winnerReward > 0 && winners.length > 0) {
            _sendRewardToWinner(winners, winnerReward);
        }

        uint256 remaining = getTotalToken(tokenAddress);
        if (remaining > 0) {
            IERC20Upgradeable(tokenAddress).safeTransfer(owner, remaining);
        }

        emit Close(block.timestamp, competition.winnerReward);
    }
}
