// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title CryptoChronicle
 * CryptoChronicle - a contract for non-fungible tokens.
 */
contract CryptoChronicle is ERC721Tradable {


    mapping(string => uint256) private copies;
    mapping(uint256 => string) private nftDictionary;
    mapping(string => uint256) private minted;
    mapping(string => uint256) private price;


    constructor(address _proxyRegistryAddress)
    ERC721Tradable("Crypto Chronicles", "CCC", _proxyRegistryAddress)
    {}



    function baseTokenURI() override public pure returns (string memory) {
        return "https://www.cryptochroniclescollection.com/api/nft/info/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.cryptochroniclescollection.com/api/nft/contract";
    }


    function getAvailableForMinting(string calldata artworkID) public view returns (uint256){
        return copies[artworkID] - minted[artworkID];
    }

    function adminCreateFirstNFT(string calldata artworkID, uint256 _copies, uint256 _price) public onlyOwner {
        require(minted[artworkID] == 0, 'This ArtWork already exists');
        require(_price > 0, 'Price not specified');
        require(_copies > 0, 'Copies not specified');
        copies[artworkID] = _copies;
        price[artworkID] = _price;
        uint256 orderNumber = minted[artworkID] + 1;
        uint256 tokenID = getTokenID(artworkID, orderNumber);
        _mint(msg.sender, tokenID);
        minted[artworkID] += 1;
    }

    function buy(string calldata artworkID) public payable returns (uint256){
        require(price[artworkID] != 0, 'Artwork does not exist');
        require(copies[artworkID] > minted[artworkID], 'All copies have already been sold');
        require(price[artworkID] == msg.value, 'Payment does not match the price');

        payable(owner()).transfer(msg.value);

        uint256 orderNumber = minted[artworkID] + 1;
        uint256 tokenID = getTokenID(artworkID, orderNumber);
        _mint(msg.sender, tokenID);
        minted[artworkID] += 1;

//        emit Buy(msg.sender, artworkID, orderNumber, tokenID, block.timestamp);

        return tokenID;
    }


    function getCopies(string calldata artworkID) public view returns (uint256){
        return copies[artworkID];
    }

    function getMinted(string calldata artworkID) public view returns (uint256){
        return minted[artworkID];
    }

    function getPrice(string calldata artworkID) public view returns (uint256){
        return price[artworkID];
    }

    function getTokenID(string calldata artworkID, uint256 orderNumber) public returns (uint256){
        string memory stringTokenId = concat(artworkID, uintToString(orderNumber));
        uint256 tokenId = uint256(keccak256(abi.encodePacked(stringTokenId)));
        nftDictionary[tokenId] = stringTokenId;
        return tokenId;
    }

    function getTokenStringId(uint256 tokenId) public view returns (string memory){
        string memory stringTokenId = nftDictionary[tokenId];
        return stringTokenId;
    }

    function uintToString(uint256 v) internal pure returns (string memory) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = abi.encodePacked(48 + remainder)[31];
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        return string(s);
    }

    function concat(string memory a, string memory b) internal pure returns (string memory){
        return string(abi.encodePacked(a, b));
    }
}
