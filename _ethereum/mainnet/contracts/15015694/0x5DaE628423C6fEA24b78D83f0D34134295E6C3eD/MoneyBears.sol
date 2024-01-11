//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

error Paused();
error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error SameAuthorizer();
error ZeroAddress();
error InvalidSender();

contract MoneyBears is ERC721A, Ownable, ReentrancyGuard{
    using Strings for uint256;
    using ECDSA for bytes32;
    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint public maxRoundTwoSupply = 8999;
    uint public maxRoundOneSupply = 1665;
    uint public roundOneMintPrice = .743 ether; // $850 USD AT TIME OF LAUNCH
    uint public roundTwoMintPrice = .743 ether; // $850 USD AT TIME OF LAUNCH
    uint public maxPublicMints = 20;

    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";

    mapping(address => uint256) public roundOneWhitelistMints;
    mapping(address => uint256) public roundTwoWhitelistMints;
    mapping(address => uint) public roundOnePublicMints;
    mapping(address => uint) public roundTwoPublicMints;

    address private wlAuthorizerRoundOne = 0x29e7844BD4b7478497dfbFb7610c51AFA3FdfF0c;
    address private wlAuthorizerRoundTwo;

    address private mintingContract;

    bool public revealed;
    bool public presaleRoundOneLive;
    bool public publicRoundOneLive;
    bool public presaleRoundTwoLive;
    bool public publicRoundTwoLive;
    
  
    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor()
        ERC721A("MoneyBears", "MBEARS")
    {
        setNotRevealedURI("ipfs://QmbYzikXso84qzQjQZKwRSi9zpTVSTVMUHugeBcCWUmcQ8");
        teamMint(0xC98Bd52AfafB99Cf17C001C7A5b37a246A782E31,18);
    }

    function teamMint(address to,uint amount) public onlyOwner {
        if(amount + totalSupply() > maxRoundTwoSupply) revert SoldOut();
        _mint(to,amount);
    }
    function airdrop(address[] calldata accounts,uint[] calldata amounts) public onlyOwner {
        require(accounts.length == amounts.length,"Arrays Don't Match");
        for(uint i; i<amounts.length;i++){
            if(amounts[i] + totalSupply() > maxRoundTwoSupply) revert SoldOut();
            _mint(accounts[i],amounts[i]);
        }
    }


    /*///////////////////////////////////////////////////////////////
                          PUBLIC SALE MINT
    //////////////////////////////////////////////////////////////*/
   function roundOneWhitelistMint(uint amount, uint max, bytes memory signature) external payable{
       bytes32 hash = keccak256(abi.encodePacked(max,msg.sender));
       if(!presaleRoundOneLive) revert SaleNotStarted();
       if(hash.toEthSignedMessageHash().recover(signature) != wlAuthorizerRoundOne) revert NotWhitelisted();
       if(msg.value < amount * roundOneMintPrice) revert Underpriced();
       if(roundOneWhitelistMints[msg.sender] + amount > max) revert MintingTooMany();
       if(totalSupply() + amount > maxRoundOneSupply) revert SoldOut(); 

       roundOneWhitelistMints[msg.sender] += amount;
       _mint(msg.sender,amount);
   }

   function roundTwoWhitelistMint(uint amount, uint max, bytes memory signature) external payable{
        bytes32 hash = keccak256(abi.encodePacked(max,msg.sender));
        if(!presaleRoundTwoLive) revert SaleNotStarted();
        if(hash.toEthSignedMessageHash().recover(signature) != wlAuthorizerRoundTwo) revert NotWhitelisted();
        if(msg.value < amount * roundTwoMintPrice) revert Underpriced();
        if(roundTwoWhitelistMints[msg.sender] + amount > max) revert MintingTooMany();
        if(totalSupply() + amount > maxRoundTwoSupply) revert SoldOut(); 

        roundTwoWhitelistMints[msg.sender] += amount;
        _mint(msg.sender,amount);
    }

   function roundOnePublicMint(uint amount) external payable {
       if(!publicRoundOneLive) revert SaleNotStarted();
       if(msg.value < amount * roundOneMintPrice) revert Underpriced();
       if(totalSupply() + amount > maxRoundOneSupply) revert SoldOut(); 
       if(roundOnePublicMints[msg.sender] + amount > maxPublicMints) revert MintingTooMany();
       roundOnePublicMints[msg.sender] += amount;
       _mint(msg.sender,amount);
   }

   function contractMint(address to, uint amount) external {
    if(mintingContract == address(0)) revert ZeroAddress();
    if(msg.sender != mintingContract) revert InvalidSender();
    if(totalSupply() + amount > maxRoundTwoSupply) revert SoldOut();
    _mint(to,amount);

   }

   function roundTwoPublicMint(uint amount) external payable {
        if(!publicRoundTwoLive) revert SaleNotStarted();
        if(msg.value < amount * roundTwoMintPrice) revert Underpriced();
        if(totalSupply() + amount > maxRoundTwoSupply) revert SoldOut(); 
        if(roundTwoPublicMints[msg.sender] + amount > maxPublicMints) revert MintingTooMany();
        roundTwoPublicMints[msg.sender] += amount;
        _mint(msg.sender,amount);
    }
   
    /*///////////////////////////////////////////////////////////////
                          METADATA UTILITIES
    //////////////////////////////////////////////////////////////*/
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

 
    /*///////////////////////////////////////////////////////////////
                                SETTERS 
    //////////////////////////////////////////////////////////////*/

    function setMaxSupply(uint round, uint256 _maxSupply) public onlyOwner {
        if(round == 1) {
            maxRoundOneSupply = _maxSupply;
        }
        if(round == 2 ){
            maxRoundTwoSupply = _maxSupply;
        }
    }
    
    function setPrice(uint round, uint newPrice) external onlyOwner{
        if(round == 1 ){
            roundOneMintPrice = newPrice;
        }
        if(round == 2 ) {
            roundTwoMintPrice = newPrice;
        }
    }

    function setRoundOneSaleState(bool presaleStatus, bool publicStatus) external onlyOwner {
        presaleRoundOneLive = presaleStatus;
        publicRoundOneLive = publicStatus;
    }
    function setRoundTwoSaleState(bool presaleStatus,bool publicStatus) external onlyOwner {
        presaleRoundTwoLive = presaleStatus;
        publicRoundTwoLive = publicStatus;
    }

    function setWlAuthorizer(uint round, address authorizer) external onlyOwner {
        if(round == 1 ){
            wlAuthorizerRoundOne = authorizer;
        }
        if(round == 2 ){
            if(authorizer == wlAuthorizerRoundOne) revert SameAuthorizer();
            wlAuthorizerRoundTwo = authorizer;
        }
    }

    function setMaxPublicMints(uint amount) external onlyOwner{
        maxPublicMints = amount;
    }

  
 
    function switchReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setMintingContract(address _contract) external onlyOwner{
        mintingContract = _contract;
    }

    /*///////////////////////////////////////////////////////////////
                                METADATA
    //////////////////////////////////////////////////////////////*/


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

    /*///////////////////////////////////////////////////////////////
                                WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

   

}


