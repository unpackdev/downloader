// SPDX-License-Identifier: GPL-3.0
// Created by NAJI
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Delegated.sol";
// Contract: DeStorm
// Author: NAJI
// Adds: @vexcooler
// ---- CONTRACT BEGINS HERE ----
pragma solidity ^0.8.0;
contract NFT is ERC721Enumerable, Delegated, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmaNRbEkcGZhvcP6bNr6zLdCmy8fbeQhXGRDtYERf8uVpE/";

    string public baseExtension = ".json";
    uint256 public maxSupply = 100;
    // Wallet Address for widthdraw
    address public BlockchainAddress = 0x7AdE7e7e26B6cCf64BbEFa6a7e93482Ae7a972D4;
    address public NFTBrandAddress = 0xE19aBD85A10Aa5321796506c2A80c3BC35eD8B00;
    // Percent for widthdraw
    uint256 public BlockchainPercent = 70;
    uint256 public NFTBrandAddressPercent = 30;
    // Percent for sell
    uint256 public sellPercent = 40;
    // Price of NFT
    uint256 public presalePrice = 0.05 ether;
    uint256 public publicPrice = 0.07 ether;
    uint256 public highPrice = 0.11 ether;
    uint256 public saleStep4Price = 0.13 ether;
    // Number of Mint Count
    uint256 public presaleCount = 100;
    uint256 public publicCount = 250;
    uint256 public highCount = 500;
    uint256 public saleStep4Count = 666;

    // Set Max Mint Number Per mint
    uint256 public maxMintAmount = 5;

    fallback() external payable {}
    receive() external payable {}

    constructor() Delegated() ERC721("MetaTars", "MT") {
      
    }
    
    
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
        if (msg.sender != owner()) {
            if (supply + _mintAmount < presaleCount) {
                require(msg.value >= presalePrice * _mintAmount);
            } else if (supply + _mintAmount < publicCount) {
                require(msg.value >= publicPrice * _mintAmount);
            } else if (supply + _mintAmount < highCount) {
                require(msg.value >= highPrice * _mintAmount);
            } else {
                require(msg.value >= saleStep4Price * _mintAmount);
            }
        }
        // Mint NFT
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    // public
    function giveAwayMint(address[] memory _to) public onlyDelegates {
        uint256 x = 0;
        uint256 supply = totalSupply();
        for (x = 0; x < _to.length; x++) {
            require(supply + x + 1 < maxSupply);
            _safeMint(_to[x], supply + x + 1);
        }
    }

    function withdrawOnTransfer() internal {
        // Widthdraw money to Blackchain Wallet
        require(payable(BlockchainAddress).send(msg.value / sellPercent));
        // Widthdraw money to NFT Brand Wallet
        require(payable(NFTBrandAddress).send(msg.value / sellPercent));
    }

    function transferTokenFrom(
        address payable _from,
        address _to,
        uint256 _tokenId
    ) public payable {
        if (_from != owner() && _to != owner()) {
            withdrawOnTransfer();
        }
        uint256 amount = msg.value - ((msg.value / sellPercent) * 2);
        approve(_to, _tokenId);
        bool sent = _from.send(amount);
        require(sent, "Failure! Ether not sent!");
        super.transferFrom(_from, _to, _tokenId);
    }   

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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
            "ERC721Metadata: URI query for nonexistent NFT"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
    //
    // ONLY THE OWNER CAN CALL THE FUNCTIONS BELOW.
    //
    // This sets the minting presale price of each NFT.
    // Example: If you pass in 0.2, then you will need to pay 0.2 ETH + gas to mint 1 NFT.
    function setPresalePrice(uint256 _newCost) public onlyDelegates {
        presalePrice = _newCost;
    }
    // This sets the minting price of each NFT.
    // Example: If you pass in 0.1, then you will need to pay 0.1 ETH + gas to mint 1 NFT.
    function setPublicPrice(uint256 _newCost) public onlyDelegates {
        publicPrice = _newCost;
    }
    // This sets the minting presale price of each NFT.
    // Example: If you pass in 0.2, then you will need to pay 0.2 ETH + gas to mint 1 NFT.
    function sethighPrice(uint256 _newCost) public onlyDelegates {
        highPrice = _newCost;
    }
    // This sets the minting step4 price of each NFT.
    // Example: If you pass in 0.2, then you will need to pay 0.2 ETH + gas to mint 1 NFT.
    function setStep4Price(uint256 _newCost) public onlyDelegates {
        saleStep4Price = _newCost;
    }
    // This sets the minting presale count.
    function setPresaleCount(uint256 _newCount) public onlyDelegates {
        presaleCount = _newCount;
    }
    // This sets the minting publicsale count.
    function setPublicCount(uint256 _newCount) public onlyDelegates {
        publicCount = _newCount;
    }
    // This sets the minting high sale count.
    function setHighSaleCount(uint256 _newCount) public onlyDelegates {
        highCount = _newCount;
    }
    // This sets the step4 count.
    function setStep4Count(uint256 _newCount) public onlyDelegates {
        saleStep4Count = _newCount;
    }
    // This sets the max supply. This will be set to 10,000 by default, although it is changable.
    function setMaxSupply(uint256 _newSupply) public onlyDelegates {
        maxSupply = _newSupply;
    }
    // This changes the baseURI.
    // Example: If you pass in "https://google.com/", then every new NFT that is minted
    // will have a URI corresponding to the baseURI you passed in.
    // The first NFT you mint would have a URI of "https://google.com/1",
    // The second NFT you mint would have a URI of "https://google.com/2", etc.
    function setBaseURI(string memory _newBaseURI) public onlyDelegates {
        baseURI = _newBaseURI;
    }
    // This sets the baseURI extension.
    // Example: If your database requires that the URI of each NFT
    // must have a .json at the end of the URI
    // (like https://google.com/1.json instead of just https://google.com/1)
    // then you can use this function to set the base extension.
    // For the above example, you would pass in ".json" to add the .json extension.
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyDelegates
    {
        baseExtension = _newBaseExtension;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function withdraw() public onlyDelegates nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "there is nothing in here");
        // marNFTBrandAddress wallet- 30% of balance
            (bool mkt, ) = payable(NFTBrandAddress).call{value: contractBalance * 30 / 100}("");
            require(mkt);
        // Blockchain wallet %70 
            (bool dev, ) = payable(BlockchainAddress).call{value: address(this).balance }("");
            require(dev);
    }
}