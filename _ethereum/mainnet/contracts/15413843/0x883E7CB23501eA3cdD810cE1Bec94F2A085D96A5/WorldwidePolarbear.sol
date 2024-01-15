// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract WorldwidePolarbear is Ownable, ERC721A, ReentrancyGuard{

    using Strings for uint256;

    constructor() ERC721A("WorldwidePolarbear","WWPB") {
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    uint256 public salePrice = 0.018 ether;
    uint256 private _totalSupply = 4000;
    uint256 private _maxPerAddress = 5;
    bool private _isPublicMintOpened = false;
    uint256 private _teamReserve = 700;
    uint256 private _reserved = 0;


    function publicMint(uint256 _quantity) external payable callerIsUser{
        require(_isPublicMintOpened, "Public mint is not open");
        require(totalSupply() + _quantity <= _totalSupply, "Exceeds the total supply");
        require(numberMinted(msg.sender) + _quantity <= _maxPerAddress, "Reached Max Supply");
        _safeMint(msg.sender, _quantity);
        refundIfOver(salePrice * _quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if(msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function reserveMint(address _address, uint256 _quantity) external onlyOwner{
        require(_address != address(0), "Can not use zero address");
        require(totalSupply() + _quantity <= _totalSupply, "Exceeds the total supply");
        require(_reserved + _quantity <= _teamReserve, "Exceeds the team reserve");
        _safeMint(_address, _quantity);
        _reserved += _quantity;
    }

    function isPublicMintOpened() public view returns(bool){
        return _isPublicMintOpened;
    }

    function setPublicMintOpened(bool _status) public onlyOwner{
        _isPublicMintOpened = _status;
    }

    function setSalePrice(uint256 _Price) public onlyOwner{
        salePrice = _Price;
    }

    bool private _blindBoxOpened = false;
    string private _blindTokenURI = "";
    string private baseTokenURI = "";

    function _baseURI() internal view override returns(string memory){
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)public view virtual override returns(string memory){
        require(_exists(tokenId), "URI query for nonexistent token");

        if(_blindBoxOpened){
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0? string(abi.encodePacked(baseURI, tokenId.toString())): "";
        } else {
            return _blindTokenURI;
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    } 

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function isBlindBoxOpened() public view returns(bool){
        return _blindBoxOpened;
    }

    function setBlindboxOpened(bool _status)public onlyOwner{
        _blindBoxOpened = _status;
    }

    function setBaseURI(string calldata uri) public onlyOwner{
        baseTokenURI = uri;
    }

    function setBlindURI(string calldata uri) public onlyOwner{
        _blindTokenURI = uri;
    }
}
