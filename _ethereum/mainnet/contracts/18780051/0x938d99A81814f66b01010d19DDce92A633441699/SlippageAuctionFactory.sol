// SPDX-License-Identifier: ISC
pragma solidity ^0.8.23;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== SlippageAuctionFactory ======================
// ====================================================================
// Factory contract for SlippageAuctions
// Frax Finance: https://github.com/FraxFinance

import "./ERC20.sol";
import "./SlippageAuction.sol";

/// @title SlippageAuctionFactory
/// @notice Permission-less factory to create SlippageAuction.sol contracts.
/// @dev https://github.com/FraxFinance/frax-bonds
contract SlippageAuctionFactory {
    /// @notice The auctions addresses created by this factory
    address[] public auctions;

    /// @notice Mapping of auction addresses to whether or not the auction has been created
    mapping(address auction => bool exists) public isAuction;

    /// @notice Creates a new auction contract
    /// @dev Tokens must be 18 decimals
    /// @param _timelock Timelock role for auction
    /// @param _tokenBuy Token used to purchase `_tokenSell`
    /// @param _tokenSell Token sold in the auction
    /// @return auction The address of the new SlippageAuction that was created
    function createAuctionContract(
        address _timelock,
        address _tokenBuy,
        address _tokenSell
    ) external returns (address auction) {
        // Reject if both tokens are not 18 decimals
        if (IERC20Metadata(_tokenBuy).decimals() != 18) {
            revert TokenBuyMustBe18Decimals();
        }
        if (IERC20Metadata(_tokenSell).decimals() != 18) {
            revert TokenSellMustBe18Decimals();
        }

        // Deploy the auction
        auction = address(new SlippageAuction({ _timelock: _timelock, _tokenBuy: _tokenBuy, _tokenSell: _tokenSell }));

        // Add auction address to mapping
        isAuction[auction] = true;

        // Add to auctions array
        auctions.push(auction);

        emit AuctionCreated({ auction: auction, tokenBuy: _tokenBuy, tokenSell: _tokenSell });
    }

    /// @notice Returns a list of all auction addresses deployed
    /// @return memory address[] The list of auction addresses
    function getAuctions() external view returns (address[] memory) {
        return auctions;
    }

    /// @notice Get an auction address by index to save on-chain gas usage from returning the whole auctions array
    /// @dev Reverts if attempting to return an index greater than the auctions array length
    /// @param _index Index of auction address to request from the auctions array
    /// @return auction Address of the specified auction
    function getAuction(uint256 _index) external view returns (address auction) {
        // Revert if non-existent
        if (_index > auctions.length) revert AuctionDoesNotExist();

        // Fetch the auction address by its index
        auction = auctions[_index];
    }

    /// @notice Returns the number of auctions deployed
    /// @return uint256 length of the auctions array
    function auctionsLength() external view returns (uint256) {
        return auctions.length;
    }

    /// @notice Emitted when a new auction is created
    /// @param auction The address of the new auction contract
    /// @param tokenBuy Token to purchase `tokenSell`
    /// @param tokenSell Token sold in the auction
    event AuctionCreated(address indexed auction, address indexed tokenBuy, address indexed tokenSell);

    /// @notice Thrown when an auction with the same sender and tokens has already been created
    error AuctionAlreadyExists();

    /// @notice Thrown when attempting to call `getAuction()` with an index greater than auctions.length
    error AuctionDoesNotExist();

    /// @notice Thrown when the sell token is not 18 decimals
    error TokenSellMustBe18Decimals();

    /// @notice Thrown when the buy token is not 18 decimals
    error TokenBuyMustBe18Decimals();
}
