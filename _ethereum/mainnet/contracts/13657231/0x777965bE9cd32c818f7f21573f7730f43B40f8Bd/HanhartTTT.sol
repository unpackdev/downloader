// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TTTERC721Base.sol";

contract HanhartTTT is TTTERC721Base {
    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory openSeaContractUri_,
        address openseaProxyRegistryAddress_,
        address payable royaltyAddress_,
        uint16 royaltyBps_
    )
        TTTERC721Base(
            name_,
            symbol_,
            openSeaContractUri_,
            openseaProxyRegistryAddress_,
            royaltyAddress_,
            royaltyBps_
        )
    {}

    // TOKEN URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Hanhart: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    // Only the contract owner (not token owner) can change metadata
    function updateTokenURI(uint256 tokenId, string calldata uri)
        public
        virtual
        onlyOwner
    {
        require(bytes(uri).length > 0, "Hanhart: no URI set for token");
        _tokenURIs[tokenId] = uri;
    }

    //
    //
    // TOKEN MINT / BURN
    //
    //
    function mint(address, uint256)
        public
        virtual
        override
        onlyOwner
        onlyUnsealed
    {
        require(false, "Hanhart: must use the mintWithUri to mint");
    }

    function mintWithUri(
        address to,
        uint256 tokenId,
        string calldata uri
    ) public virtual onlyOwner onlyUnsealed {
        require(bytes(uri).length > 0, "Hanhart: no URI set for token");
        _safeMint(to, tokenId);
        _tokenURIs[tokenId] = uri;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
