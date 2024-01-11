// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
 
contract WittyRhinoClub is ERC721A, Ownable {

     using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public unRevealedUri;
    uint256 public publicSaleCost = 0.07 ether;
    uint256 public preSaleCost = 0.05 ether;
    uint256 public maxSupply = 10000;
    uint256 public preSaleMaxSupply = 3888;
    uint256 public publicSaleMintAmount = 10;
    uint256 public preSaleMintAmount = 5;
    uint256 public wittyMaxMint = 200;
    bool public revealed = false;

    uint256 private _reservedWittyTokens;
    mapping(address => uint256) public perAddressMintedBalance;
    uint256 public mintState = 0;


    constructor(string memory name, string memory symbol, string memory _unRevealedUri) ERC721A(name, symbol) {
        unRevealedUri = _unRevealedUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function publicMint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Minimum 1 NFT Mint.");
        require(supply + _mintAmount <= maxSupply, "SoldOut.");
        uint256 wittyMintedCount = perAddressMintedBalance[msg.sender];
        if (msg.sender != owner()) {
            require(mintState > 0, "The Witty Mint Is Paused.");

            if(mintState == 1){
                require(msg.value >= preSaleCost * _mintAmount, "Insufficient Funds");
                require(supply + _mintAmount <= preSaleMaxSupply, "PreSale SoldOut!");
                require(
                wittyMintedCount + _mintAmount <= preSaleMintAmount,
                "Wallet Limit Reached"
                );
            } else if (mintState == 2) {
                require(msg.value >= publicSaleCost * _mintAmount, "Insufficient Funds");
                 require(
                wittyMintedCount + _mintAmount <= publicSaleMintAmount,
                "Wallet Limit Reached"
            );
            }
        }
        perAddressMintedBalance[msg.sender] = wittyMintedCount + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
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

        if (revealed == false) {
            return unRevealedUri;
        }

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

    // Witty Nft Reserved for Marketing.

    function wittyMint(uint256 _mintAmount) public onlyOwner {
        require(_reservedWittyTokens + _mintAmount <= wittyMaxMint, "Witty Already Reserved.");
        _reservedWittyTokens += _mintAmount;
         _safeMint(msg.sender, _mintAmount);
    }

    //only owner

    function wittyReveal(bool reveal_) public onlyOwner {
        revealed = reveal_;
    }


    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintState(uint256 _mintState) public onlyOwner {
        mintState = _mintState;
    }

    function setUnRevealedURI(string memory _unRevealedURI) public onlyOwner {
        unRevealedUri = _unRevealedURI;
    }

    function setPublicSaleMintAmount(uint256 _newPublicSaleMintAmount) public onlyOwner {
        publicSaleMintAmount = _newPublicSaleMintAmount;
    }

     function setPreSaleMintAmount(uint256 _newPreSaleMintAmount) public onlyOwner {
        preSaleMintAmount = _newPreSaleMintAmount;
    }

    function setPublicSaleMintCost(uint256 _price) public onlyOwner {
        publicSaleCost = _price;
    }

    function setPreSaleMintCost(uint256 _price) public onlyOwner {
        preSaleCost = _price;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}