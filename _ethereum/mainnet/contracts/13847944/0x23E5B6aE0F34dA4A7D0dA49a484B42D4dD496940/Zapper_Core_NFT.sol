// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Avatar NFTs for Zapper team
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract Zapper_Core_NFT is ERC721URIStorage, Ownable {
    uint256 public totalSupply;

    constructor() ERC721("Zapper Core", "ZPR CORE") {}

    function mint(address to, string memory _tokenURI) external onlyOwner {
        _mintNFT(to, _tokenURI);
    }

    function mintMultiple(address[] memory to, string[] memory _tokenURI)
        external
        onlyOwner
    {
        uint256 count = to.length;
        require(_tokenURI.length == count);

        for (uint256 i = 0; i < count; i++) {
            _mintNFT(to[i], _tokenURI[i]);
        }
    }

    function _mintNFT(address to, string memory _tokenURI) internal {
        uint256 tokenId = ++totalSupply;
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
}
