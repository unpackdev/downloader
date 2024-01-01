// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./DataTypes.sol";

interface IKyokoPoolLiquidator {
    event LiquidationCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user,
        address nft,
        uint256 id,
        uint256 amount,
        uint256 time
    );

    event BidCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user,
        uint256 amount,
        uint256 time
    );

    event ClaimCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user,
        uint256 time
    );

    /**
     * @dev Function to liquidate an expired borrow info.
     * @param borrowId The id of liquidate borrow target
     **/
    function liquidationCall(uint256 borrowId, uint256 amount)
        external payable returns (uint256, string memory);

    /**
     * @dev Function to bid for the liquidate auction.
     * @param borrowId The id of liquidate borrow target
     **/
    function bidCall(uint256 borrowId, uint256 amount) external payable returns (address, uint256);

    /**
     * @dev Function to claim the liquidate NFT.
     * @param borrowId The id of liquidate borrow target
     **/
    function claimCall(uint256 borrowId) external  returns (uint256, string memory);
}