// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFolkTraits.sol";

contract RareFolkTraits is Ownable, IFolkTraits {
    using Strings for uint256;
    string private _baseURI;

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId.toString()))
                : "";
    }
}
