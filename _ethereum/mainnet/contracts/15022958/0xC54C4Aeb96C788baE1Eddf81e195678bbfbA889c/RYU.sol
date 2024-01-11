//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract RYU is ERC721A, Ownable, ReentrancyGuard {
    uint256 public numberOfToken;
    uint256 public wlMintPrice = 0.005 ether;
    uint256 public mintPrice = 0.01 ether;
    uint256 private _totalSupply = 888;
    string private _baseTokenURI;
    string private revealUri;
    bool public isSaleEnabled = true;
    bool public isWlSaleEnabled = true;
    bool public revealed = true;

    constructor() ERC721A("RYU","RYU") {
        numberOfToken = 0;
        sethiddenBaseURI("https://gateway.pinata.cloud/ipfs/QmUiNboyWjamLedC7iXf6MM26Smkm6YdrbAbD4p8NbT47N");
    }


    function ownerMint(uint256 _amount, address _address) public onlyOwner { 
        require((_amount + numberOfToken) <= (_totalSupply), "No more NFTs");

        _safeMint(_address, _amount);
        numberOfToken += _amount;
    }

    function whitelistMint(uint256 _amount) external payable nonReentrant {
        require(isWlSaleEnabled, "mint: Whilte List sale paused");
        require(msg.value == wlMintPrice * _amount, "Value sent is not correct");
        require((_amount + numberOfToken) <= (_totalSupply), "No more NFTs");

        _safeMint(msg.sender, _amount);
        numberOfToken += _amount;
    }

    function mint(uint256 _amount) public payable nonReentrant {
        require(isSaleEnabled, "mint: Paused");
        require(msg.value == mintPrice * _amount, "Value sent is not correct");
        require((_amount + numberOfToken) <= (_totalSupply), "No more NFTs");
         
        _safeMint(msg.sender, _amount);
        numberOfToken += _amount;
    }

    function setWlPrice(uint256 newPrice) external onlyOwner {
        wlMintPrice = newPrice;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setReveal(bool bool_) external onlyOwner {
        revealed = bool_;
    }
    
    function enableSale(bool bool_) external onlyOwner {
        isSaleEnabled = bool_;
    }

    function enableWhitelistSale(bool bool_) external onlyOwner {
        isWlSaleEnabled = bool_;
    }

    function sethiddenBaseURI(string memory uri_) public onlyOwner {
        revealUri = uri_;
    }

    function setBaseURI(string memory uri_) public onlyOwner {
        _baseTokenURI = uri_;
    }

    function currentBaseURI() private view returns (string memory){
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(revealed == false) {
            return revealUri;
        }
        return string(abi.encodePacked(currentBaseURI(), Strings.toString(tokenId), ".json"));
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{
        value: address(this).balance
        }("");
        require(success, "Failed to withdraw.");
    }
}