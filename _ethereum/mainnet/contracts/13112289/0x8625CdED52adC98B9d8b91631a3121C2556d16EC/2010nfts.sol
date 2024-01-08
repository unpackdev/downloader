// SPDX-License-Identifier: Prima Nocta

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;  

/*
      |\      _,,,---,,_
ZZZzz /,`.-'`'    -.  ;-;;,_
     |,4-  ) )-,_. ,\ (  `'-'
    '---''(_/--'  `-'\_)      

*/

contract TWENTYTENNFTS is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    //uint256 public constant price = 550000000000000000; // 0.55 BNB
    uint256 public constant price = 100000000000000000;    // 0.1 ETH
    //uint256 public constant price = 600000000000000000000; // 600 FTM
    //uint256 public constant price = 200000000000000000000; // 200 MATIC
    
    uint256 public MAX_NFT = 2010;

    struct InfoStuff {
        string url;
        bool nsfw;
    }
    mapping(uint256 => InfoStuff) public tokenInfo;

    constructor() ERC721("TWENTYTENNFTS", "2010") {
        _setBaseURI("m0jGVlbea2dsldNzapzi");
    }

    function adjustInfo(uint256 _tokenid, bool _nsfw) public onlyOwner {
        InfoStuff storage info = tokenInfo[_tokenid];
        info.nsfw = _nsfw;
    }

    function bigArrayOfImages() public view returns (InfoStuff[] memory) {
        InfoStuff[] memory images = new InfoStuff[](MAX_NFT);
        for (uint i = 0; i < MAX_NFT; i++) {
            images[i].url = string(abi.encodePacked(tokenURI(i)));
            images[i].nsfw = tokenInfo[i].nsfw;
        }
        return images;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (_exists(_tokenId) == false) {
            string memory base = baseURI();
            return string(abi.encodePacked(base));
        }
        return string(abi.encodePacked(tokenInfo[_tokenId].url));
    }

    function publishNFT(uint256 _tokenid, string memory _url, bool _nsfw) public {
        require(ownerOf(_tokenid) == msg.sender, "howcouldyou?");
        InfoStuff storage info = tokenInfo[_tokenid];
        info.url = _url;
        info.nsfw = _nsfw;
    }

    function mintNFT(uint256[] memory tokenIds, string[] memory tokenUrls, bool _nsfw) public payable {
        uint256 numberOfTokens = tokenIds.length;

        require(totalSupply().add(numberOfTokens) <= MAX_NFT, "idiot");
        require(price.mul(numberOfTokens) == msg.value, "stupid");
        require(tokenIds.length == tokenUrls.length, "fixedit");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            require(tokenIds[i] <= 2009, "ffsdudeareukiddingmerightnow");
            InfoStuff storage info = tokenInfo[tokenIds[i]];
            info.url = tokenUrls[i];
            info.nsfw = _nsfw;
            _safeMint(msg.sender, tokenIds[i]);
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function ownerWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}
