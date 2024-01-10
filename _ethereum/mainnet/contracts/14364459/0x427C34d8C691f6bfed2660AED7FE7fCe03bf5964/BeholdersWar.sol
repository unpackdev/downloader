//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BeholdersWar is ERC721Enumerable, Ownable {

    uint private constant PRICE = 0.075 ether;
    uint private constant PRICE_RANDOM = 0.05 ether;

    string private baseTokenURI;
    uint[2] openTokens;
    uint[] soldedTokenIds;

    event MintNft(address senderAddress, uint256 nftToken, uint256 price);
    event MintNfts(address senderAddress, uint256[] nftTokens);
    event Withdraw(uint balance, uint w1, uint w2, uint w3);
    event BaseURI(string url);
    event OpenTokens(uint[2] openedTokens);


    constructor(string memory baseURI)  ERC721("Beholders War", "BeWar") {
        setBaseURI(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BaseURI(baseTokenURI);
    }

    function setOpenTokens(uint from, uint to) public onlyOwner {
        require(from >= 1, "Wrong parameters");
        require(to <= 10000, "Wrong parameters");
        openTokens[0] = from;
        openTokens[1] = to;
        emit OpenTokens(openTokens);
    }

    function reserveNFT(uint _tokenId) public onlyOwner {
        require(!checkSoldTokens(_tokenId), "Token is sold");
        _mintSingleNFT(_tokenId, 0);
    }

    function reserveSeveralNFTs(uint[] memory _tokenIds) public onlyOwner {
        bool isSold = false;
        for (uint i = 0; i < _tokenIds.length; i++) {
            isSold = checkSoldTokens(_tokenIds[i]);
            if(isSold) {
                break;
            }
        }

        require(!isSold, "Token is sold");

        for (uint i = 0; i < _tokenIds.length; i++) {
            _safeMint(msg.sender, _tokenIds[i]);
            soldedTokenIds.push(_tokenIds[i]);
        }
         emit MintNfts(msg.sender, _tokenIds);
    }

    function mintNFT(uint _tokenId) public payable {
        require(_tokenId >= openTokens[0] && _tokenId <= openTokens[1], "Token is closed");

        require(!checkSoldTokens(_tokenId), "Token is sold");

        require(msg.value >= PRICE, "Not enough ether to purchase NFTs.");

        _mintSingleNFT(_tokenId, 1);
    }

    function mintRandomNFT(uint[3] memory _tokenIds) public payable {
        require(msg.value >= PRICE_RANDOM, "Not enough ether to purchase NFT.");

        require(_tokenIds[0] != _tokenIds[1] && _tokenIds[1] != _tokenIds[2] && _tokenIds[0] != _tokenIds[2], "Token ids cannot be the same");

        require(_tokenIds[0] >= openTokens[0] && _tokenIds[0] <= openTokens[1], "Token is closed");
        require(_tokenIds[1] >= openTokens[0] && _tokenIds[1] <= openTokens[1], "Token is closed");
        require(_tokenIds[2] >= openTokens[0] && _tokenIds[2] <= openTokens[1], "Token is closed");

        require(!checkSoldTokens(_tokenIds[0]), "Token is sold");
        require(!checkSoldTokens(_tokenIds[1]), "Token is sold");
        require(!checkSoldTokens(_tokenIds[2]), "Token is sold");

        uint randomIndex = random(_tokenIds.length);
        uint _tokenId = _tokenIds[randomIndex];

        _mintSingleNFT(_tokenId, 2);
    }

    function _mintSingleNFT(uint _tokenId, uint price) private {
        _safeMint(msg.sender, _tokenId);
        soldedTokenIds.push(_tokenId);
        emit MintNft(msg.sender, _tokenId, price);
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        uint wo = balance * 6 / 10;
        uint wt = balance * 2 / 10;
        uint wth = balance * 2 / 10;
        (bool successo, ) = (address(0x7E0b5769AC3A2D1b61b5e92747eC0aa0C548AeB2)).call{value: wo}("");
        (bool successt, ) = (address(0x033D24A2FCDD1e3DD4aeFC63C2B6402d2A687fFb)).call{value: wt}("");
        (bool successth, ) = (address(0x9F730Bc8a2B496A7Af042A8Ae7DDE5918d8CCF49)).call{value: wth}("");
        require(successo && successt && successth, "Transfer failed.");
        emit Withdraw(balance, wo, wt, wth);
    }

    function getBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }


    function getSoldTokenIds() external view onlyOwner returns (uint[] memory) {
        return soldedTokenIds;
    }

    function getOpenTokens() external view onlyOwner returns (uint[2] memory) {
        return openTokens;
    }

    function random(uint number) public view returns (uint256){
        uint256 seed = uint256(keccak256(abi.encodePacked(
                block.timestamp + block.difficulty +
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                block.gaslimit +
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                block.number
            )));

        return (seed - ((seed / number) * number));
    }

    function checkSoldTokens(uint _tokenId) private view returns (bool){
        bool isTokenSold = false;
        for (uint i = 0; i < soldedTokenIds.length; i++) {
            if(soldedTokenIds[i] == _tokenId) {
                isTokenSold = true;
                break;
            }
        }

        return isTokenSold;
    }
}
