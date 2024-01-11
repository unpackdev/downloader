// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "ERC721.sol";

import "IClubMintPass.sol";


contract ClubMintPass is IClubMintPass, ERC721("RKL Club Mint Pass", "RKLCMP") {

    address public immutable admin;
    address[] public minters;
    /// @dev will give us the number of clubs the user can mint
    mapping(address => uint256) public numClubs;

    string private _mintPassBaseURI = "";
    bool private burnEnabled = false;
    uint256 private tokenID = 1;

    /// Modifiers

    modifier onlyOwner() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// Constructor

    constructor() {
        admin = msg.sender;
    }

    /// @inheritdoc IClubMintPass
    function batchMint(address[] calldata to) external onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], tokenID);
            tokenID += 1;
        }
    }

    /// @inheritdoc IClubMintPass
    function burnMintPass(uint256 tokenID_) external {
        // to avoid having people accidentally burn
        if (burnEnabled == false) {
            revert BurnNotEnabled();
        }
        // burner must be the owner of the tokenID_
        address owner = ownerOf(tokenID_);
        if (owner != msg.sender) {
            revert NotOwner(tokenID_);
        }
        // burn the token and add the user to Club minters
        _burn(tokenID_);
        // add the burner as qualified to mint the actual Club NFT
        minters.push(msg.sender);
        // also keep track of how many clubs the address is allowed to mint
        if (numClubs[msg.sender] > 0) {
            numClubs[msg.sender] += 1;
        } else {
            numClubs[msg.sender] = 1;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _mintPassBaseURI;
    }

    /// Admin
    function flipBurn() external onlyOwner {
        burnEnabled = !burnEnabled;
    }

    function setBaseURI(string memory mintPassBaseURI) external onlyOwner {
        _mintPassBaseURI = mintPassBaseURI;
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
 * ClubMintPass.sol
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
