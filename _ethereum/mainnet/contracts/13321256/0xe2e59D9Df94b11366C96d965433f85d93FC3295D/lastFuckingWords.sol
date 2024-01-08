// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract LastFuckingWords is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {

    string public baseURI;
    uint256 public maxSupply = 66;

    uint256 public price = 0.0666 ether;
    bool public saleStarted = false;
    uint256 public maxReserved = 10;

    address public immutable artist;
    address public immutable devs;

    modifier whenSaleActive() {
        require(saleStarted, 'Fking sale not started');
        _;
    }

    constructor(address _artist, address _devs) ERC721("LastFuckingWords", "LFW") {
        baseURI = 'https://last-fking-words.s3.eu-west-2.amazonaws.com/t/';
        artist = _artist;
        devs = _devs;
    }

    function mint() external payable whenSaleActive nonReentrant {
        uint256 supply = totalSupply();
        require(supply < maxSupply, "No fking one left.");
        require(msg.value >= price, "You fking trying to steal me?");

        _safeMint(msg.sender, getNextTokenId());

        if (msg.value > price) {
            Address.sendValue(payable(msg.sender), msg.value - price);
        }
    }

    function getNextTokenId() internal view returns(uint256) {
        uint256 ret = 1;
        while(_exists(ret)) {
            ret++;
        }
        return ret;
    }

    function mintReserved(address _receiver, uint256 _tokenId) external onlyOwner {
        require(maxReserved > 0, 'No fking reserve left.');
        require(!_exists(_tokenId), 'Fking token already given.');
        maxReserved--;
        _safeMint(_receiver, _tokenId);
    }

    function startSale() public onlyOwner {
        require(saleStarted == false, 'Sale already started.');
        saleStarted = true;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        uint256 splitDevs = (balance / 100) * 35;
        uint256 splitArtist = balance - splitDevs;

        Address.sendValue(payable(artist), splitArtist);
        Address.sendValue(payable(devs), splitDevs);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}