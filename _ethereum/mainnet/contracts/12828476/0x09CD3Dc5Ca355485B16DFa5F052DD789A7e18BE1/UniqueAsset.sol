// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract UniqueAsset is  ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    address marketplace;

    constructor() ERC721("UniqueAsset", "DOVE") {
        marketplace = msg.sender;
    }

    function setMarketplace(address _marketplace) public{
        require(marketplace == msg.sender,'permission');
        marketplace = _marketplace;
    }

    function mintUniqueToken(string calldata _tokenURI)
    external returns(uint _tokenId)
    {
        require(msg.sender == marketplace,'sender');
        _tokenId = totalSupply() + 1;
        super._mint(marketplace, _tokenId);
        super._setTokenURI(_tokenId, _tokenURI);
        return _tokenId;
    }

    //overrides
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

}
