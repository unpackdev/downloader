// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

interface HolderInterface {
    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract BastardApes is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 public MAX_APES = 7777;
    uint256 public MAX_CLAIMABLE_APES = 1000;
    uint256 public maxApePurchase = 20;
    bool public isSaleActive = false;

    uint256 private _price = 0.02 ether;

    mapping(address => bool) private _claimed;
    uint256 public totalClaimed = 0;

    HolderInterface private _holderContract;

    constructor(string memory baseURI, address holdersAddress) ERC721("Bastard GAN Apes", "BGANAPES")  {
        setBaseURI(baseURI);
        _holderContract = HolderInterface(holdersAddress);

        // owner gets the first 10 apes
        _safeMint(msg.sender, 0);
        _safeMint(msg.sender, 1);
        _safeMint(msg.sender, 2);
        _safeMint(msg.sender, 3);
        _safeMint(msg.sender, 4);
        _safeMint(msg.sender, 5);
        _safeMint(msg.sender, 6);
        _safeMint(msg.sender, 7);
        _safeMint(msg.sender, 8);
        _safeMint(msg.sender, 9);
    }

    function mintApe(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(isSaleActive, "Sale is not currently active");
        require(num <= maxApePurchase, "Exceeds maxApePurchase");
        require(supply + num <= MAX_APES, "Exceeds MAX_APES");
        require(msg.value >= _price * num, "Ether sent is not correct");

        for(uint256 i; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function claimApe() public {
        uint256 supply = totalSupply();
        require(isSaleActive, "Sale is not currently active");
        require(supply + 1 <= MAX_APES, "Exceeds MAX_APES");
        require(supply + 1 <= MAX_CLAIMABLE_APES, "Exceeds MAX_CLAIMABLE_APES");
        require(!_claimed[msg.sender], "Address already claimed");

        require(_holderContract.balanceOf(msg.sender) > 0, "Must own an ape");

        _safeMint(msg.sender, supply);
        totalClaimed += 1;
        _claimed[msg.sender] = true;
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function toggleSaleActive() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
