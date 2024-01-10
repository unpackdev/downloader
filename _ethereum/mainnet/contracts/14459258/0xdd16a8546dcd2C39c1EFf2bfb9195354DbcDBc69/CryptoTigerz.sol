//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract CryptoTigerz is ERC721A, Ownable, ReentrancyGuard{
    using Strings for uint256;


    uint256 public maxSupply = 10000;
    uint256 public price = 0.05 ether;
    uint256 public maxPublicMint = 10;

    string public baseURI;
    string public notRevealedUri;
    string  public uriSuffix = '.json';

    bool public revealed = false;
    //When deploying set this to true if you don't want people to be able to mint off the bat
    bool public paused = false;
    mapping(address => uint256) public tokensMinted;


 
    constructor()
        ERC721A("Crypto Tigerz NFT", "CTT")
    {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmTtk5Q131F1wuUv8PjnCs1TrMcRNQwfCdRsvAfXvYfyo6");
    }

    modifier whenNotPaused{
        require(paused == false, "Contract is paused");
        _;
    }

    //GETTERS



    function getPrice() public view returns (uint256) {
        return price;
    }


    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }



    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPublicMint(uint256 _maxMint) public onlyOwner {
        maxPublicMint = _maxMint;
    }

    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function switchPause() public onlyOwner {
        paused = !paused;
    }   

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    //END SETTERS





    //MINT FUNCTIONS

   
    //Public Sale Mint
    function publicMint(uint256 amount) external payable whenNotPaused nonReentrant { 
        uint256 supply = totalSupply();
        require(msg.sender == tx.origin,"Caller != Contract");
        require(amount > 0, "You must mint at least one NFT.");
        require(tokensMinted[msg.sender] + amount <= maxPublicMint, "You can't mint more NFTs!");
        require(supply + amount <= maxSupply, "Sold out!");

        require(msg.value >= price * amount, " Insuficient funds");

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }


    function teamMint(uint256 amount) external onlyOwner nonReentrant {
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply, "Sold out!");
        _safeMint(msg.sender,amount);
    }

    function teamAirdrop(address to, uint256 amount)external onlyOwner nonReentrant{
        uint256 supply = totalSupply();
        require(supply + amount <= maxSupply,"Sold Out!");
        _safeMint(to,amount);
    }

    

    // END MINT FUNCTIONS

    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),uriSuffix))
                : "";
    }

    //Withdraw
      function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        //Pay 5% To Dev
        (bool dev,) = payable(0x6884efd53b2650679996D3Ea206D116356dA08a9).call{value: (balance * 5)/ 100}("");
        require(dev);
        //Rest To Founding Team
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    // =============================================================================
  }
}