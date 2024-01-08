pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Autograph is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant DEV_SALE_PRICE = 1000000000000000; // 0.001 ETH
    uint256 public constant RELEASE_PRICE = 100000000000000000; // 0.1 ETH
    uint256 public constant MAX_DEV_SALE_AUTOGRAPHS = 100;
    uint256 public constant MAX_PRE_SALE_AUTOGRAPHS = 1000; // 100 DEV + 900 PRE 
    uint256 public constant MAX_PUBLIC_SALE_AUTOGRAPHS = 10000; // 100 DEV + 900 PRE + 9000 PUB
    uint public constant MAX_DEV_SALE_PURCHASE = 5;
    uint public constant MAX_PRE_SALE_PURCHASE = 1;
    uint public constant MAX_PUBLIC_SALE_PURCHASE = 5;

    bool public devSaleIsActive = false;
    bool public preSaleIsActive = false;
    bool public publicSaleIsActive = false;

    string _baseTokenURI = "https://gateway.pinata.cloud/ipfs/";
    address _sherrbssAddress = 0x797c43B044b3f7DD97a5b5BD4df9a656B343744E;
    address _synodiclesAddress = 0xE8050bb4811D73ce52141d8fc9306A2c17636b36;

    mapping (uint256 => string) private _tokenURIs;

    constructor() ERC721("Autograph", "AUTOGRAPH") {
        _baseTokenURI = "https://gateway.pinata.cloud/ipfs/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURIHash) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = string(abi.encodePacked(_baseURI(), _tokenURIHash));
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory) {
        return _tokenURIs[_tokenId];
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function mintDevAutograph(string[] memory tokenURIHash, uint numberOfTokens) public payable {
        require(devSaleIsActive, "Dev sale must be active to mint Autographs");
        require(numberOfTokens <= MAX_DEV_SALE_PURCHASE, "Can only mint 5 autographs at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_DEV_SALE_AUTOGRAPHS, "Purchase would exceed max supply of autographs allocated for the dev sale.");
        require(DEV_SALE_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_DEV_SALE_AUTOGRAPHS) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex, tokenURIHash[i]);
            }
        }
    }

    function mintPresaleAutograph(string memory tokenURIHash) public payable {
        require(preSaleIsActive, "Presale must be active to mint Autographs");
        require(totalSupply().add(1) <= MAX_PRE_SALE_AUTOGRAPHS , "Purchase would exceed max supply of autographs allocated for the presale.");
        require(RELEASE_PRICE <= msg.value, "Ether value sent is not correct");

        uint mintIndex = totalSupply();
        if (totalSupply() < MAX_PRE_SALE_AUTOGRAPHS) {
            _safeMint(msg.sender, mintIndex);
            _setTokenURI(mintIndex, tokenURIHash);
        }
    }
    
    function mintAutograph(string[] memory tokenURIHash, uint numberOfTokens) public payable {
        require(publicSaleIsActive, "Public sale must be active to mint Autographs");
        require(numberOfTokens <= MAX_PUBLIC_SALE_PURCHASE, "Can only mint 5 autographs at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_PUBLIC_SALE_AUTOGRAPHS, "Purchase would exceed max supply of autographs allocated for the public sale.");
        require(RELEASE_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_PUBLIC_SALE_AUTOGRAPHS) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex, tokenURIHash[i]);
            }
        }
    }

    function flipDevSaleState() public onlyOwner {
        devSaleIsActive = !devSaleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipPublicSaleState() public onlyOwner {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURIHash) public onlyOwner {
        _setTokenURI(tokenId, _tokenURIHash);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _sherrbssPortion = address(this).balance * 95/100;
        uint256 _synodiclesPortion = address(this).balance * 5/100;
        require(payable(_sherrbssAddress).send(_sherrbssPortion));
        require(payable(_synodiclesAddress).send(_synodiclesPortion));
    }
}
