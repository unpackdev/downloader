//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract InvisibleKevins is ERC721A, Ownable {
    uint256 public maxSupply = 2222;
    uint256 public price = 0.0069 ether;
    uint256 public freeMints = 469;
    string public baseURI;
    bool public baseURILocked;

    address public payee;

    event Mint(address indexed _to, uint256 _amount);

    constructor() ERC721A("Invisible Kevins", "IKEV") {
        payee = msg.sender;
    }

    function mint(uint256 _amount) external payable {
        require(_amount <= 10, "Max 10 per transaction");
        require(totalSupply() + _amount < maxSupply, "Exceeds max supply");
        if (totalSupply() + _amount > freeMints) {
            if (totalSupply() < freeMints) {
                require(msg.value >= price * (totalSupply() + _amount - freeMints), "Sent incorrect Ether");
            } else {
                require(msg.value >= price * _amount, "Sent incorrect Ether");
            }
        }
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, _amount);
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdraw() external onlyOwner {
        payee.call{value: address(this).balance}("");
    }
}
