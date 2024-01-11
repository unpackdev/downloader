//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract CryptoFarm is ERC721A, Ownable {
    string private _contractBaseURI;
    string private _contractURI;
    string private _tokenMetadata;
    uint8 private _nftPerUser;
    uint16 private _nftThreshold;
    mapping(address => uint8) private usersNFTQuantity;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        string memory tokenMetadata_,
        uint8 nftPerUser_,
        uint16 nftThreshold_
    ) ERC721A(name_, symbol_) {
        _contractBaseURI = baseURI_;
        _contractURI = contractURI_;
        _tokenMetadata = tokenMetadata_;
        _nftPerUser = nftPerUser_;
        _nftThreshold = nftThreshold_;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_contractBaseURI, _contractURI));
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function setNftThreshold(uint16 _threshold) public onlyOwner {
        _nftThreshold = _threshold;
    }

    function getNftThreshold() public view returns (uint16) {
        return _nftThreshold;
    }

    function setNftPerUser(uint8 nftPerUser_) public onlyOwner {
        _nftPerUser = nftPerUser_;
    }

    function getNftPerUser() public view returns (uint8) {
        return _nftPerUser;
    }

    function setTokenUri(string memory _metadata) public onlyOwner {
        _tokenMetadata = _metadata;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URIQueryForNonexistentToken");
        require(
            bytes(_contractBaseURI).length != 0,
            "CryptoFarm: Base uri is null"
        );

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, _tokenMetadata));
    }

    function mint() public {
        require(
            totalSupply() <= _nftThreshold,
            "cryptoFarm: Reached NFT threshold"
        );
        require(
            usersNFTQuantity[msg.sender] < _nftPerUser,
            "cryptoFarm: user owns max number of NFT/s"
        );
        usersNFTQuantity[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }
}
