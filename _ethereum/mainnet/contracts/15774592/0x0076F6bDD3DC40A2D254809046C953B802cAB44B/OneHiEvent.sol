// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract OneHiEvent {
    event CreateTable(address tableAddr, address makerAddr, address nftAddr, uint256 targetAmount);
    event BuyTickets(address tableAddr, address player, uint256 start, uint256 end);
    event UpdateHiStatus(address nftAddr, address miniNFTAddr, address fftAddr,
        bool isSupport, uint256 createTableFee);
    event UpToTargetAmount(address tableAddr);
    event ChooseWinner(address tableAddr, address winner, uint256 winnerNumber);
    event ClaimTreasure(address tableAddr);
    event LuckyClaim(address tableAddr);
    event SplitProfit(address tableAddr, address makerAddr, uint256 makeAmount, address vaultAddr, uint256 vaultAmount);
    event UpdateRatio(uint8 splitProfitRatio, uint8 luckySplitProfitRatio);

    function _emitCreateTableEvent(address tableAddr, address makerAddr, address nftAddr,
        uint256 targetAmount) internal {
        emit CreateTable(tableAddr, makerAddr, nftAddr, targetAmount);
    }
    function _emitUpdateHiStatusEvent(address nftAddr, address miniNFTAddr, address fftAddr,
        bool isSupport, uint256 createTableFee) internal {
        emit UpdateHiStatus(nftAddr, miniNFTAddr, fftAddr, isSupport, createTableFee);
    }
    function _emitBuyTicketsEvent(address tableAddr, address player, uint256 start, uint256 end) internal {
        emit BuyTickets(tableAddr, player, start, end);
    }
    function _emitUpToTargetAmountEvent(address tableAddr) internal {
        emit UpToTargetAmount(tableAddr);
    }
    function _emitChooseWinnerEvent(address tableAddr, address winner, uint256 winnerNumber) internal {
        emit ChooseWinner(tableAddr, winner, winnerNumber);
    }
    function _emitClaimTreasureEvent(address tableAddr) internal {
        emit ClaimTreasure(tableAddr);
    }
    function _emitLuckyClaimEvent(address tableAddr) internal {
        emit LuckyClaim(tableAddr);
    }
    function _emitSplitProfitEvent(address tableAddr, address makerAddr, uint256 makerAmount, address vaultAddr, uint256 vaultAmount) internal {
        emit SplitProfit(tableAddr, makerAddr, makerAmount, vaultAddr, vaultAmount);
    }
    function _emitUpdateRatio(uint8 splitProfitRatio, uint8 luckySplitProfitRatio) internal {
        emit UpdateRatio(splitProfitRatio, luckySplitProfitRatio);
    }
}