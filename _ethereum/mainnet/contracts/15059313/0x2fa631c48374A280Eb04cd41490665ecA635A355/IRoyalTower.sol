// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import "./IBaseContractController.sol";

interface IRoyalTower is IBaseContractController {
    event DAOTreasureDeposit(
        address indexed sender,
        uint256 queeneAuctionId,
        uint256 value
    );

    event DAOTreasureWithdraw(
        address indexed payed,
        uint256 withdrawId,
        uint256 value
    );

    function depositToDAOTreasure(uint256 _queeneAuctionId) external payable;

    function retrieveAuctionFallbackFunds() external;
}
