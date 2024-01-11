// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "INFTContract.sol";


interface IClubMintPass {

    error BurnNotEnabled();
    error NotAdmin();
    error NotOwner(uint256);

    /// @notice Utility function to conveniently send all the club
    /// nfts to the winners of the auction.
    /// @param to addresses of winners. Each of these receives one
    /// mint pass nft.
    function batchMint(address[] calldata to) external;

    /// @notice Each owner of the NFT is able to call this function.
    /// It will destroy their mint pass and will write into storage
    /// of the contract the address of the burner. This will then be
    /// used as a whitelist address that will mint the actual club
    /// NFT.
    /// @param tokenID token ID to burn. Caller must be owner.
    function burnMintPass(uint256 tokenID) external;

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
 * IClubMintPass.sol
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
