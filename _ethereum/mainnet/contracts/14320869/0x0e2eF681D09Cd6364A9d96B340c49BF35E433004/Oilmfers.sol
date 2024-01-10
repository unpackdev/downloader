//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Oilmfers is ERC721A, Ownable {
    uint256 price = 0.0169 ether;
    uint256 balance;
    uint16 maxSupply = 1111;
    uint16 freeToken = 111;
    uint8 tXN = 10;

    string public baseURI;

    bool public saleActive = false;

    mapping(address => bool) private alreadyMinted;

    constructor(string memory _baseURI) ERC721A("Oilmfers", "OM") {
        setBaseURI(_baseURI);
    }

    // MINT
    function mint(uint256 _count) external payable {
        require(saleActive == true, "Sale is not active!");
        require(totalSupply() < maxSupply, "Sold out!");
        require(tx.origin == msg.sender, "No bots!");

        if (totalSupply() < freeToken) {
            require(
                !alreadyMinted[msg.sender] && _count == 1,
                "1 free mint per wallet!"
            );
            require(msg.value == 0, "Please mint for free!");
            _safeMint(msg.sender, _count);
            alreadyMinted[msg.sender] = true;
        } else {
            require(_count <= tXN, "Exceeds max per transaction!");
            require(totalSupply() + _count <= maxSupply, "Exceeds max supply!");
            require(_count > 0, "Must mint at least one token!");
            require(_count * price == msg.value, "Invalid funds provided!");
            _safeMint(msg.sender, _count);
        }
    }

    // ADMIN

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token!");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setPrice(uint256 _newPrice) public {
        price = _newPrice;
    }

    function withdraw() external onlyOwner {
        uint256 bal = address(this).balance;
        uint256 share1 = (bal * 17) / 100;

        Address.sendValue(
            payable(0x36273f9c2660ad6b4f9d678C1A88a50Ba8D34A24),
            share1
        );

        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function reserveNFTs() public onlyOwner {
        _safeMint(_msgSender(), 11);
    }

    function flipSaleState() external onlyOwner {
        saleActive = !saleActive;
    }
}
