// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/************************************************************
_       _          _     _ _
_ __ (_)_ __ | | __  ___| |__ (_) |_    __ _ _ __   ___
| '_ \| | '_ \| |/ / / __| '_ \| | __|  / _` | '_ \ / _ \
| |_) | | | | |   <  \__ \ | | | | |_  | (_| | |_) |  __/
| .__/|_|_| |_|_|\_\ |___/_| |_|_|\__|  \__,_| .__/ \___|
|_|                                          |_|
*************************************************************/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


abstract contract ApeOwnership is Ownable, ERC721Enumerable  {
    uint256 public _totalAddNum = 0;
    string private _baseUrl;
    uint256 public TotalLimit = 9999;
    mapping (uint256 => string) private _tokenURIs;
    constructor()  ERC721("Pink Shit APE", "PSA") {
        _baseUrl= "https://metadata.pinkshitape.com/metadata/";
    }

    function setBaseURI(string memory _baseSiteUrl) public onlyOwner {
        _baseUrl = _baseSiteUrl;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUrl;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return string(abi.encodePacked(super.tokenURI(tokenId),  ".json"));
    }
}


contract PinkShiApe is ApeOwnership {
    mapping(address => uint256) public mintMap;
    uint256 public payForMint = 30000000000000000;

    function buy(uint256 amount) public payable {
        require(amount > 0,'mint num limit');
        mintMap[msg.sender] = mintMap[msg.sender] + amount;
        require(mintMap[msg.sender] <=5,'mint 5 per wallet');
        require(msg.value >= payForMint*amount,"pay limit");
        for(uint256 i = 0; i < amount; i++){
            _totalAddNum++;
            require(TotalLimit >= _totalAddNum,"total supply limit");
            _mint(msg.sender, _totalAddNum);
        }
    }

    function withdrawFund(uint val) external onlyOwner {
        payable(msg.sender).transfer(val);
    }
}
