// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TimerController.sol";

abstract contract AvantArteDrawInterface {
    /// @dev an event to call when a token is purchased - mostly used to email users of aa
    event OnPurchase(
        address walletAddress,
        uint256 tokenId,
        string productId,
        string accountId
    );

    /// @dev the cost to purchase
    function cost(uint256 tokenId) external view virtual returns (uint256);

    /// @dev tells us if the token is available
    function isActive() external view virtual returns (bool);

    /// @dev tells us if the token is available
    function isAllowedToPurchase(uint256 tokenId)
        external
        view
        virtual
        returns (bool);

    /// @dev returns the count of items that can be purchased
    function count(uint256 tokenId) external view virtual returns (uint256);

    /// @dev called to purchase a token
    function purchase(
        uint256 tokenId,
        string calldata productId,
        string calldata accountId
    ) external payable virtual;

    /// @dev called to get an available token id when using non unique tokens
    function getAvailableTokenId() external view virtual returns (uint256);

    /// @dev returns the timer data
    function getTimerData() external view virtual returns (TimerData memory);
}
