// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract BJPBadgeNFT is ERC721, ERC721URIStorage, Ownable {

    mapping(uint256 => bool) private _tokenIds;

    constructor() ERC721("BJP Badge", "BJPB") {}

    function safeMint(address to, string memory tokenUri, uint256 serialNumber)
    public
    onlyOwner
    {
        require(_tokenIds[serialNumber] == false, "serial number already defined");
        _tokenIds[serialNumber] = true;

        _safeMint(to, serialNumber);
        _setTokenURI(serialNumber, tokenUri);
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
