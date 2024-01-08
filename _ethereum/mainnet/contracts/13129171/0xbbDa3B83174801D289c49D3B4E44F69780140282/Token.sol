// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Dirty Robot's Seasons
 * An NFT powered by Ether Cards - https://ether.cards
 */

 
contract Token is ERC721Tradable  {
    string      _tokenURI    = "https://client-metadata.ether.cards/api/dirtyrobot/";
    string      _contractURI = "https://client-metadata.ether.cards/api/dirtyrobot/contract";
    string      public loeuf = "https://www.youtube.com/watch?v=-wop47G2qeY";
    uint256  constant    public _sale_start = 1630422000;
    uint256  constant    public _sale_end = _sale_start + 7 days;
     constructor(address _proxyRegistryAddress)
        ERC721Tradable("Dirty Robot Seasons", "SEASONS", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public view returns (string memory) {
        return _tokenURI;
    }

    function setTokenURI(string memory _uri) external onlyOwner {
        _tokenURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        _contractURI = _uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override {
        require( (block.timestamp > _sale_end) || (from == address(0)),"Tokens cannot be moved until the end of the sale");
        super._beforeTokenTransfer(from,to,_tokenId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    

}
