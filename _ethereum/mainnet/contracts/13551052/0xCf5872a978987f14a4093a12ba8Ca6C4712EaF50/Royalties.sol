// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./Balances.sol";

abstract contract Royalties is Balances, ReentrancyGuard {
    using SafeMath for uint256;

    function getValidRoyaltyIndex() private view returns (uint8 index) {
        index = addressToIndex[msg.sender];
        require(index > 0, NO_ACCESS);
    }

    function withdrawTeamMemberRoyaltyTo(address to, uint256 valueToWithdraw)
        public
    {
        uint8 index = getValidRoyaltyIndex() - 1;
        uint256 value = currentTeamRoyalty[index];
        require(value > 0, NO_BALANCE);
        require(value >= valueToWithdraw, TOO_MANY);

        valueToWithdraw = valueToWithdraw > 0 ? valueToWithdraw : value;
        currentTeamRoyalty[index] = value - valueToWithdraw;
        totalRoyaltyWithdrawed += valueToWithdraw;

        depositor.withdrawTo(to, valueToWithdraw);
    }

    /**
     * @dev Change the interval when the royalties can be shared
     * @param royaltyInterval_ time to collect royalties
     */
    function changeRoyaltyInterval(uint256 royaltyInterval_) public onlyOwner {
        require(royaltyInterval != royaltyInterval_, SAME_VALUE);
        royaltyInterval = royaltyInterval_;
    }

    /**
     * @dev Create a new royalty stage to collecty royalties
     * Current stage would become available for royalty withdrawing
     */
    function nextRoyaltyStage() public onlyOwner {
        require(canChangeRoyaltyStage(), DISABLED_CHANGES);
        _nextRoyaltyStage();
    }

    /**
     * @dev Get last royalty stage index
     */
    function getLastRoyaltyStageIndex() internal view returns (uint256) {
        return royaltyStages.length - 1;
    }

    /**
     * @dev Create a new royalty stage
     */
    function _nextRoyaltyStage() private {
        uint256 valueAdded = address(depositor).balance -
            (totalRoyaltyAdded - totalRoyaltyWithdrawed);
        totalRoyaltyAdded += valueAdded;

        uint256 communityRoyalty = valueAdded / 5; // 20%

        uint256 teamRoyalty = valueAdded - communityRoyalty;
        for (uint8 i; i < receiverAddresses.length; i++) {
            currentTeamRoyalty[i] +=
                (teamRoyalty * receiverPercentages[i]) /
                100;
        }

        uint256 lastIndex = getLastRoyaltyStageIndex();
        royaltyStages[lastIndex].endDate = block.timestamp;
        royaltyStages[lastIndex].amount = communityRoyalty;
        royaltyStages[lastIndex].totalSupply = totalSupply();

        royaltyStages.push(RoyaltyStage(block.timestamp, 0, 0, 0, 0));
    }

    /**
     * @dev Check if a new royalty stage can be created
     */
    function canChangeRoyaltyStage() private view returns (bool) {
        RoyaltyStage memory lastStage = royaltyStages[
            getLastRoyaltyStageIndex()
        ];
        uint256 valueAdded = address(depositor).balance -
            (totalRoyaltyAdded - totalRoyaltyWithdrawed);
        return
            valueAdded > 0 &&
            (block.timestamp - lastStage.startDate) >= royaltyInterval;
    }

    /**
     * @dev Create a new royalty stage if it's possible on each mint/transfer
     * Used when tokens are transferred
     */
    function _tryToChangeRoyaltyStage() internal {
        if (canChangeRoyaltyStage()) {
            _nextRoyaltyStage();
        }
    }

    /**
     * @dev Withdraw royalties for all royalty stages that the sender didn't collect royalties
     * The royalties are based on the tokens that the sender holded on each royalty stage
     * @param to address that will receive the royalty
     * @param inputTokenId for which to collect royalties
     */
    function withdrawRoyaltyOfTokenTo(address to, uint256 inputTokenId) public {
        _withdrawRoyaltyOfTokenTo(msg.sender, to, inputTokenId);
    }

    function _withdrawRoyaltyOfTokenTo(
        address from,
        address to,
        uint256 inputTokenId
    ) internal {
        uint256 userLastIndex = ownerRoyaltyStageIndex[from];
        uint256 lastIndex = getLastRoyaltyStageIndex();
        require(userLastIndex < lastIndex, NO_BALANCE);

        bool hasInputToken = inputTokenId > 0;

        uint256 royaltyAmount;
        for (uint256 i = userLastIndex; i < lastIndex; i++) {
            RoyaltyStage memory stage = royaltyStages[i];
            if (stage.amount == 0) {
                continue;
            }
            uint256 eligibleTokenCount;
            uint256 n = hasInputToken ? 1 : ownerTokenList[from].length;
            for (uint256 j; j < n; j++) {
                uint256 tokenId;
                if (hasInputToken) {
                    tokenId = inputTokenId;
                } else {
                    tokenId = ownerTokenList[from][j];
                }
                if (royaltyTokenClaimed[i][tokenId]) {
                    continue;
                }

                NFTDetails memory details = ownedTokensDetails[from][tokenId];
                if (
                    stage.startDate <= details.starTime &&
                    details.endTime < stage.endDate
                ) {
                    eligibleTokenCount++;
                    royaltyTokenClaimed[i][tokenId] = true;
                }
            }
            if (eligibleTokenCount == 0) {
                continue;
            }
            royaltyStages[i].totalWithdrawals += eligibleTokenCount;
            royaltyAmount +=
                (stage.amount / stage.totalSupply) *
                eligibleTokenCount;
        }
        require(royaltyAmount > 0, NO_BALANCE);

        if (!hasInputToken) {
            ownerRoyaltyStageIndex[from] = lastIndex;
        }

        totalRoyaltyWithdrawed += royaltyAmount;

        depositor.withdrawTo(to, royaltyAmount);
    }

    function withdrawUnclaimedRoyaltyTo(address to)
        public
        onlyOwner
        nonReentrant
    {
        uint256 royaltyToWitdraw;
        for (
            uint256 i = unclaimedRoyaltyStageIndex;
            i < royaltyStages.length;
            i++
        ) {
            RoyaltyStage memory stage = royaltyStages[i];
            if ((block.timestamp - stage.startDate) < WITHDRAW_ROYALTY_TIME) {
                unclaimedRoyaltyStageIndex = i;
                break;
            }
            uint256 unclaimedCount = stage.totalSupply - stage.totalWithdrawals;
            if (unclaimedCount == 0) {
                continue;
            }
            royaltyStages[i].totalWithdrawals = stage.totalSupply;
            royaltyToWitdraw +=
                unclaimedCount *
                (stage.amount / stage.totalSupply);
        }

        require(royaltyToWitdraw > 0, NO_BALANCE);

        totalRoyaltyWithdrawed += royaltyToWitdraw;

        depositor.withdrawTo(to, royaltyToWitdraw);
    }
}
