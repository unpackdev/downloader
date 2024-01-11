// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract BabyPablo is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    bool public mintIsLive = false;
    uint256 public collectionSize = 10000;
    uint256 public freeAllocate = 1500;
    uint256 public freeTxLimit = 5;
    uint256 public regTxLimit = 10;
    uint256 public constant cost = 0.005 ether;
    string public uri = "";
    string public uriExt = ".json";
    mapping(address => uint256) public freeMintTracker;
    mapping(address => uint256) public regMintTracker;

    constructor (
        string memory _uri
    ) ERC721A ("BabyPablo", "BBP") {
        setUri(_uri);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function setMintIsLive(bool _status) public onlyOwner {
        mintIsLive = _status;
    }

    function setUri(string memory _newUri) public onlyOwner {
        uri = _newUri;
    }

    function setUriExt(string memory _newUriExt) public onlyOwner {
        uriExt = _newUriExt;
    }

    function setFreeTxLimit (uint256 _freeTxLimit) public onlyOwner {
        freeTxLimit = _freeTxLimit;
    }

    function setRegTxLimit (uint256 _regTxLimit) public onlyOwner {
        regTxLimit = _regTxLimit;
    }

    function setCollectionSize (uint256 _collectionSize) public onlyOwner {
        collectionSize = _collectionSize;
    }

    function setFreeAllocate (uint256 _freeAllocate) public onlyOwner {
        freeAllocate = _freeAllocate;
    }

    function mint(uint256 _mintAmount) public payable {
        require(mintIsLive, "Mint not started.");
        require(totalSupply() + _mintAmount <= collectionSize, "No available supply left to mint.");
        require(_mintAmount > 0, "Invalid mint amount.");

        if (freeAllocate > totalSupply()) {
            require(_mintAmount <= freeTxLimit, "Invalid Free Txn Limit.");
            require(freeMintTracker[msg.sender] + _mintAmount <= freeTxLimit, "Invalid Free Txn Limit.");
            require(totalSupply() + _mintAmount <= freeAllocate, "Invalid Free Allocate Supply.");
            freeMintTracker[msg.sender] += _mintAmount;
        } else {
            require(_mintAmount <= regTxLimit, "Invalid Txn Limit.");
            require(regMintTracker[msg.sender] + _mintAmount <= regTxLimit, "Invalid Txn Limit.");
            require(msg.value == cost * _mintAmount, "Ethers provided is invalid.");
            regMintTracker[msg.sender] += _mintAmount;
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokensOwned = new uint256[](ownerTokenCount);
        uint256 thisTokenId = _startTokenId();
        uint256 tokensOwnedIndex = 0;
        address latestOwnerAddress;

        while (tokensOwnedIndex < ownerTokenCount && thisTokenId <= collectionSize) {
            TokenOwnership memory ownership = _ownerships[thisTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                tokensOwned[tokensOwnedIndex] = thisTokenId;

                tokensOwnedIndex++;
            }
            thisTokenId++;
        }
        return tokensOwned;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token not found.");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), uriExt))
            : '';
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, "Withdrawal is unavailable.");
    }
}