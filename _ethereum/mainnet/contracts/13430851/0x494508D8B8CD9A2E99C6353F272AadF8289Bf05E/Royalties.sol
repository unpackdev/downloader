// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./Balances.sol";

abstract contract Royalties is Balances, ReentrancyGuard {
    using SafeMath for uint256;

    function getValidRoyaltyIndex() internal view returns (uint8 index) {
        index = addressRoyaltyToIndex[msg.sender];
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

    function getCurrentTeamMemberRoyaltyToWithdraw()
        public
        view
        returns (uint256)
    {
        uint8 index = getValidRoyaltyIndex() - 1;
        return currentTeamRoyalty[index];
    }

    function changeTeamMemberRoyaltyAddress(address newAddress) public {
        uint8 index = getValidRoyaltyIndex();
        addressRoyaltyToIndex[msg.sender] = 0;
        addressRoyaltyToIndex[newAddress] = index;
        royaltyReceiverAddresses[index - 1] = newAddress;
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
     * @dev get all the royalty stage details
     */
    function getRoyalityStages() public view returns (RoyaltyStage[] memory) {
        return royaltyStages;
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
    function getLastRoyaltyStageIndex() public view returns (uint256) {
        return royaltyStages.length - 1;
    }

    /**
     * @dev Create a new royalty stage
     */
    function _nextRoyaltyStage() internal {
        uint256 lastIndex = getLastRoyaltyStageIndex();
        uint256 valueAdded = address(depositor).balance -
            (totalRoyaltyAdded - totalRoyaltyWithdrawed);

        totalRoyaltyAdded += valueAdded;

        uint256 totalTeamRoyalty;
        for (uint8 i; i < royaltyReceiverAddresses.length; i++) {
            uint256 teamMemberRoyalty = (valueAdded *
                royaltyReceiverPercentages[i]) / 100;

            currentTeamRoyalty[i] += teamMemberRoyalty;

            totalTeamRoyalty += teamMemberRoyalty;
        }

        royaltyStages[lastIndex].endDate = block.timestamp;
        royaltyStages[lastIndex].amount = valueAdded;

        royaltyStages.push(RoyaltyStage(block.timestamp, 0, 0));
    }

    /**
     * @dev Check if a new royalty stage can be created
     */
    function canChangeRoyaltyStage() public view returns (bool) {
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
}
