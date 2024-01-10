// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Ownable.sol";
import "./ERC721Burnable.sol";

contract WrappedERC721 is ERC721Burnable, Ownable {
    // Mapping from tokenID to metadata
    mapping(uint256 => string) private _metadata;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function safeMint(
        address to,
        uint256 tokenId,
        string memory metadata
    ) public onlyOwner {
        _safeMint(to, tokenId);

        _metadata[tokenId] = metadata;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "WrappedERC721: URI query for nonexistent token"
        );

        return _metadata[tokenId];
    }

    function burn(uint256 tokenId) public virtual override onlyOwner {
        super.burn(tokenId);

        delete _metadata[tokenId];
    }
}
