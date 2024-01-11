// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IAuctionFactory {
    error NotAdmin();

    /// @notice Creates minimal proxy contract for auction
    /// @param floorPrice Floor bid price. Bids can't be places that are
    /// lower than this price
    /// @param auctionEndBlock Ethereum block index at which the auction
    /// ends
    /// @param salt Used for deterministic clone deploy
    function createAuction(
        uint256 floorPrice,
        uint256 auctionEndBlock,
        bytes32 salt
    ) external returns (address);

    /// @notice Creates minimal proxy contract for whitelisted auction.
    /// This is where only holders of a certain NFT collection are
    /// allowed to participate
    /// @param floorPrice Floor bid price. Bids can't be places that are
    /// lower than this price
    /// @param auctionEndBlock Ethereum block index at which the auction
    /// ends
    /// @param whitelistedCollection Ethereum address of the NFT collection
    /// that is whitelisted to participate in the auction
    /// @param salt Used for deterministic clone deploy
    function createWhitelistedAuction(
        uint256 floorPrice,
        uint256 auctionEndBlock,
        address whitelistedCollection,
        bytes32 salt
    ) external returns (address);
}

/*
 * 88888888ba  88      a8P  88
 * 88      "8b 88    ,88'   88
 * 88      ,8P 88  ,88"     88
 * 88aaaaaa8P' 88,d88'      88
 * 88""""88'   8888"88,     88
 * 88    `8b   88P   Y8b    88
 * 88     `8b  88     "88,  88
 * 88      `8b 88       Y8b 88888888888
 *
 * IAuctionFactory.sol
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 Rumble League Studios Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
