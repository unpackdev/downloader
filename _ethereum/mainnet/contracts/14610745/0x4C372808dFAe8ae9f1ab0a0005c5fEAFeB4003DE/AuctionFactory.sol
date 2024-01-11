// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "INFTContract.sol";
import "IAuctionFactory.sol";
import "IAuction.sol";
import "Clones.sol";

contract AuctionFactory is IAuctionFactory {
    /// Uses https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/ pattern

    address public immutable admin;
    /// @dev Clones will be made off of this deployment
    IAuction auctionAddress;

    /// Modifiers

    modifier onlyOwner() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// Constructor

    constructor() {
        admin = msg.sender;
    }

    /// @inheritdoc IAuctionFactory
    function createAuction(
        uint256 floorPrice,
        uint256 auctionEndTimestamp,
        bytes32 salt
    ) external override onlyOwner returns (address) {
        address copy = Clones.cloneDeterministic(address(auctionAddress), salt);
        IAuction auctionCopy = IAuction(copy);
        auctionCopy.initialize(floorPrice, auctionEndTimestamp, INFTContract(address(0)));
        return copy;
    }

    /// @inheritdoc IAuctionFactory
    function createWhitelistedAuction(
        uint256 floorPrice,
        uint256 auctionEndTimestamp,
        address whitelistedCollection,
        bytes32 salt
    ) external override onlyOwner returns (address) {
        address copy = Clones.cloneDeterministic(address(auctionAddress), salt);
        IAuction auctionCopy = IAuction(copy);
        auctionCopy.initialize(
            floorPrice,
            auctionEndTimestamp,
            INFTContract(whitelistedCollection)
        );
        return copy;
    }

    /// Admin

    /// @notice If there is ever a need, new club auctions can be cloned
    /// by setting this to a different address.
    /// @param initAuctionAddress make clones off this contract
    function setAuctionAddress(address initAuctionAddress) external onlyOwner {
        auctionAddress = IAuction(initAuctionAddress);
    }
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
 * AuctionFactory.sol
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
