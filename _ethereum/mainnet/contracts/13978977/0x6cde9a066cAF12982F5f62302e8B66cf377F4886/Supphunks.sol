// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
                            .__                  __            
  ________ ________ ______ |  |__  __ __  ____ |  | __  ______
 /  ___/  |  \____ \\____ \|  |  \|  |  \/    \|  |/ / /  ___/
 \___ \|  |  /  |_> >  |_> >   Y  \  |  /   |  \    <  \___ \ 
/____  >____/|   __/|   __/|___|  /____/|___|  /__|_ \/____  >
     \/      |__|   |__|        \/           \/     \/     \/ 
 */

import "./ERC721.sol";
import "./Ownable.sol";

contract SuPPhunks is ERC721, Ownable {
    using Strings for uint256;

    string private baseURI;
    uint256 public cost = 0.03 ether;
    // avoiding <= :)
    uint256 public maxSupplyPlusOne = 2501;
    uint256 public maxMintPlusOne = 21;
    uint256 public psMaxMintPlusOne = 6;
    bool public saleActive = false;
    bool public preSaleActive = false;
    uint256 public totalSupply;

    string private merkleRoot;

    constructor() ERC721("suPPhunks", "SUPP") {}

    modifier mintRequirements(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && totalSupply + _mintAmount < maxSupplyPlusOne,
            "Purchase would exceed max tokens for sale"
        );
        require(msg.sender == tx.origin, "No smart contracts please");
        _;
    }

    // for grand Phunks!
    function mint(uint256 _mintAmount)
        public
        payable
        mintRequirements(_mintAmount)
    {
        require(_mintAmount < maxMintPlusOne);
        require(saleActive, "Public sale  is not active");
        require(msg.value >= cost * _mintAmount, "Wrong price");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, totalSupply + i);
        }
        unchecked {
            totalSupply += _mintAmount;
        }
    }

    // for our supPhunks
    function mintOgSupp(uint256 _mintAmount, string memory _merkleProof)
        public
        payable
        mintRequirements(_mintAmount)
        presaleCheck(_merkleProof)
    {
        require(_mintAmount < psMaxMintPlusOne);
        require(preSaleActive, "Presale is not active");
        require(
            balanceOf(msg.sender) < psMaxMintPlusOne,
            "You already minted max amount for presale"
        );

        require(msg.value >= 0.02 ether * _mintAmount);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, totalSupply + i);
        }
        unchecked {
            totalSupply += _mintAmount;
        }
    }

    // for our ogPhunks
    function mintOgPhunk(uint256 _mintAmount, string memory _merkleProof)
        public
        payable
        mintRequirements(_mintAmount)
        presaleCheck(_merkleProof)
    {
        require(_mintAmount < psMaxMintPlusOne);
        require(preSaleActive, "Presale is not active");
        require(msg.value >= 0.01 ether * _mintAmount, "Wrong price");
        require(
            balanceOf(msg.sender) < psMaxMintPlusOne,
            "You already minted max amount for presale"
        );
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mint(msg.sender, totalSupply + i);
        }
        unchecked {
            totalSupply += _mintAmount;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintPlusOne = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function togglePresale() public onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function withdraw() public payable onlyOwner {
        // here we pay our team(7% per team member)
        uint256 part = (address(this).balance * 70) / 1000;
        payable(0x830dcf019102ed1a71FB74063BD47a142594ebc8).transfer(part);
        payable(0xa28FEd1c717ba029Da21574aea041b378203bE26).transfer(part);
        payable(0x4fB7cb98FAC9670B7F20B09C96c92C3566bd2860).transfer(part);
        payable(0x2FA0bD091B78D9ef6A2fa308A562DEB8B5C5019B).transfer(part);
        payable(0xA75e789E3d7C59E352FCd9CAcbCE72CcBEe64EE6).transfer(part);

        // this are the funds for continuation of game and project development
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // MerkleTree Methods
    function setMerkleRoot(string memory _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    modifier presaleCheck(string memory _merkleProof) {
        require(
            keccak256(abi.encodePacked(_merkleProof)) ==
                keccak256(abi.encodePacked(merkleRoot))
        );
        _;
    }
}
