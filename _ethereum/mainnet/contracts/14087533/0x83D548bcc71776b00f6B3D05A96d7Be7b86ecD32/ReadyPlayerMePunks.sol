// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";


contract ReadyPlayerMePunks is ERC721, ERC721URIStorage, ERC721Enumerable
{
    string constant METADATA_URL = "https://funks.some.me/api/funks/";
    string constant METADATA_SUFFIX = "/meta";
    uint constant NFT_PRICE = 0.0001 ether;
    address constant PARENT_TOKEN_ADDRESS = 0x6faAFd105d4137f60e7b9165D1C395dc0166585C;
    uint16 constant MAX_ASSETS = 10000;

    uint[MAX_ASSETS] private _assets;
    mapping(uint => bool) public _assetExists;


    constructor() ERC721("TestFunks", "EXP2")
    {
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }


    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function mint(uint _parentTokenIndex) public payable 
    {
        ERC721 _parentToken = ERC721(PARENT_TOKEN_ADDRESS);
        require(_parentToken.ownerOf(_parentTokenIndex) == msg.sender, "Parent token owner and sender mismatch.");
        require(!_assetExists[_parentTokenIndex], "The asset does not meet the unique constraint.");
        require(msg.value >= NFT_PRICE, "Not enough ETH sent.");

        uint _id = totalSupply();
        _assets[_id] = _parentTokenIndex;
        _mint(msg.sender, _id);
        _setTokenURI(_id, string(abi.encodePacked(METADATA_URL, Strings.toString(_id), METADATA_SUFFIX)));
        _assetExists[_parentTokenIndex] = true;
    }


    function batchMint(uint[] memory _parentTokenIndices) public payable
    {
        require(msg.value >= NFT_PRICE * _parentTokenIndices.length, "Not enough ETH sent.");
        ERC721 _parentToken = ERC721(PARENT_TOKEN_ADDRESS);

        for (uint i = 0; i < _parentTokenIndices.length; i++)
        {
            require(_parentToken.ownerOf(_parentTokenIndices[i]) == msg.sender, "Parent token owner and sender mismatch.");
            require(!_assetExists[_parentTokenIndices[i]], "The asset does not meet the unique constraint.");

            uint _id = totalSupply();
            _assets[_id] = _parentTokenIndices[i];
            _mint(msg.sender, _id);
            _setTokenURI(_id, METADATA_URL);
            _assetExists[_parentTokenIndices[i]] = true;
        }
    }


    function getParentToken(uint tokenId) public view returns(uint parentId)
    {
        parentId = _assets[tokenId];
    }


    function getTokenPrice() public pure returns(uint price)
    {
        price = NFT_PRICE;
    }
}
