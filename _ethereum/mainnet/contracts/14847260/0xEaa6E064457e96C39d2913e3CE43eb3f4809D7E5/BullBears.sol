// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BullBears is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 3725;
    uint256 public constant MAX_MINT = 5;
    mapping(address => uint256) public totalPublicMint;
    string private _baseTokenURI = "ipfs://QmTBayVgFVa5dBFjeN4yv35eJo9t3q8EMPKXAcyXSFgW5R/";
    string private _baseTokenHiddenURI = "ipfs://QmNdsmRb1wXnk2UH79RvCyW4DxbWVadBpSbytmZGVjqp4V/hidden.json";
    bool public isReady = true;
    bool public isRevealed = false;


    constructor () ERC721A("BullBears", "BULLS") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contracts cannot call");
        _;
    }

    function mint(uint256 _quantity) external payable nonReentrant callerIsUser{
        require(isReady, "Sale is passive");
        require(_quantity > 0, "Cannot mint none");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "No enough NFTs left");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_MINT, "Cannot mint more than 5");
        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }
    function setNotRevealedURI(string memory _URI) external onlyOwner {
        _baseTokenHiddenURI = _URI;
    }

    function setReady(bool _state) external onlyOwner {
        isReady = _state;
    }

    function setRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require( _exists(_tokenId),"no token");

        if (isRevealed == false) {
            return _baseTokenHiddenURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : "";
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool ok, ) = payable(owner()).call{value: address(this).balance}("");
        require(ok);
    }
}