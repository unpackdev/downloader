// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2022 zapper

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
///@notice Honorary NFTs for the Zapper community
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract Zapper_Honorary_NFT is ERC1155, Ownable {
    uint256 public lastTokenId;

    string public constant name = "Zapper Honorary NFT";
    string public constant symbol = "ZPR HONORARY";

    // Mapping from token ID to token URI
    mapping(uint256 => string) private idToUri;

    error IdDoesNotExist();

    constructor() ERC1155("") {}

    /**
    * @dev Returns the uri of a token given its ID
    * @param _id ID of the token to query
    * @return uri of the token or an empty string if it does not exist
    */
    function uri(uint256 _id) public view override returns (string memory) {
        return idToUri[_id];
    }

    /**
    * @dev Mints 1 token of id `_id` to each address in `_to`
    * @param _id ID of the token to mint
    * @param _to Array of addresses to mint the NFT to
    */
    function mint(uint256 _id, address[] memory _to) external onlyOwner {
        if (_id > lastTokenId) {
            revert IdDoesNotExist();
        }

        for(uint256 i=0; i<_to.length; i++) {
            _mint(_to[i], _id, 1, "");
        }
    }

    /**
    * @dev Registers new token
    * @param _uri Metadata URI for the token
    */
    function addToken(string memory _uri) external onlyOwner {
        uint256 newTokenId = ++lastTokenId;

        idToUri[newTokenId] = _uri;
        emit URI(_uri, newTokenId);
    }

    /**
    * @dev Update URI for existing token
    * @param _id token's id
    * @param _uri New metadata URI
    */
    function updateToken(uint256 _id, string memory _uri) external onlyOwner {
        if (_id > lastTokenId) {
            revert IdDoesNotExist();
        }

        idToUri[_id] = _uri;
        emit URI(_uri, _id);
    }
}
