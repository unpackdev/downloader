// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Base64.sol";


contract OnChainSVG is ERC721Enumerable, Ownable {

    string[99] private svgImages;
    string private NFTname;
    string private description;
    uint256 types = 99;

    mapping(uint256=>bool) private minted_;


    constructor() ERC721("Sekaiscape", "SKSCP") {}


    function mint(address _to, uint256 _tokenId) public onlyOwner {
        require((_tokenId > 0 ) && (_tokenId <= types ), "tokenId must be between 1 and 99");
        _safeMint(_to, _tokenId);
        minted_[_tokenId] = true;
    }

    function bulkMint(address[] memory _toList, uint256[] memory _tokenIdList) public onlyOwner {
        require(_toList.length == _tokenIdList.length, "input length must be same");
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            mint(_toList[i], _tokenIdList[i]);
        }
    }

    function setImages(uint256 _tokenId, string memory _string) public onlyOwner {
        require(bytes(svgImages[_tokenId-1]).length == 0, "Data can be set once");
        require((_tokenId > 0 ) && (_tokenId <= types ), "tokenId must be between 1 and 99");
        svgImages[_tokenId - 1] = _string;
        
    }

    function getImage(uint256 _tokenId) private view returns (string memory) {
        require((_tokenId > 0 ) && (_tokenId <= types ), "tokenId must be between 1 and 99");
        return svgImages[_tokenId-1];
    }

    function setName(string memory _string) public onlyOwner  {
        require(bytes(NFTname).length == 0, "Name can be set once");
        NFTname = _string;
    }

    function setDescription(string memory _string) public onlyOwner  {
        require(bytes(description).length == 0, "Description can be set once");
        description = _string;
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory) {

        require(minted_[_tokenId]==true,"This token has not been minted.");

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', NFTname , ' #', Strings.toString(_tokenId), '", "description": "',description,'", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(getImage(_tokenId))), '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
}