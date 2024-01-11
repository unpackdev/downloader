//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

error Paused();
error SoldOut();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error IncorrectGorillaCount();
error WrongOwner();
error WrongGorillaType();

contract CyberKings is ERC721A, Ownable, ReentrancyGuard{
    using Strings for uint256;
    using ECDSA for bytes32;

    /*///////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public maxSupply = 300;

    uint256 public ethMintPrice = .1 ether;
    
    /*


    To do:: adjust maxSupply  and the modifier so there's no conflict with our teamMints


    */

    /// @dev The amount of CYBER it costs to mint one CyberKing. 
    uint cyberMintPrice = 25000 ether;
    /// @dev The amount of normal adult gorillas it costs to mint one CyberKing. 
    uint adultBurnsRequired = 5;
    /// @dev The amount of genesis gorillas it costs to mint one CyberKing. 
    uint genesisBurnsRequired = 1;

    uint16 teamMints;
    uint16 reservedForTeam = 25;

    CyberToken public cyber;
    CyberGorilla public cyberGorillas;


    mapping(uint => bool) public isGenesis;
    mapping(address => bool) public isWhitelisted;

    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = '.json';

    bool public revealed = true;

    /// @dev When deploying set this to true if you don't want people to be able to mint off the bat
    bool public paused = true;
    mapping(address => uint256) public tokensMinted;

    mapping(address => uint) adultMints;
    mapping(address => uint) genesisMints;
    mapping(address => uint) ethMints;

    uint maxMints = 10;
  
    MintSetup public mintSetup = MintSetup(0, 190, 10, 0, 50, 10, 0, 35, 1);

    struct MintSetup {
        uint16 adultMintCount;
        uint16 maxAdultMintCount;
        uint16 maxAdultMintsPerPerson;

        uint16 genesisAdultMintCount;
        uint16 maxGensisAdultMintCount;
        uint16 maxGenesisMintsPerPerson;

        uint16 ethMintCount;
        uint16 maxEthMintSupply;
        uint16 maxEthMintsPerPerson;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor()
        ERC721A("CyberKings", "CGK")
    {
        setBaseURI("https://cyberkings.s3.amazonaws.com/json/");
        teamMint(1);

        // @dev we mint the first 10 to host them for auctions::These are the 1/1's
    }

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier whenNotPaused{
        if(paused) revert Paused();
        _;
    }

    modifier notSoldOut(){
        if(totalSupply() > maxSupply) revert SoldOut();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                          PUBLIC SALE MINT
    //////////////////////////////////////////////////////////////*/
   
    function mintForEth(uint amount) external payable whenNotPaused notSoldOut {
        if(tokensMinted[msg.sender] + amount > maxMints) revert MintingTooMany();
        if(ethMints[msg.sender] + amount > mintSetup.maxEthMintsPerPerson) revert MintingTooMany();
        if(!isWhitelisted[msg.sender]) revert NotWhitelisted();
        if(msg.value < amount * ethMintPrice) revert Underpriced();
        if(mintSetup.ethMintCount + amount > mintSetup.maxEthMintSupply) revert MintedOut();

        mintSetup.ethMintCount+= uint16(amount);
        ethMints[msg.sender] += amount;
        tokensMinted[msg.sender] +=amount;
        _safeMint(msg.sender, amount);
    }

    function mintForAdult(uint amount, uint[] calldata tokenIds) external whenNotPaused notSoldOut {
        if(tokensMinted[msg.sender] + amount > maxMints) revert MintingTooMany();
        if(tokenIds.length != amount * adultBurnsRequired) revert IncorrectGorillaCount();
        if(adultMints[msg.sender] + amount > mintSetup.maxAdultMintsPerPerson) revert MintingTooMany();
        if(mintSetup.adultMintCount + amount > mintSetup.maxAdultMintCount) revert MintedOut();

        for(uint i; i < tokenIds.length; i++){
            if(isGenesis[tokenIds[i]]) revert WrongGorillaType();
        }

        transferCyber(cyberMintPrice * amount);
        burnBatchForOwner(tokenIds);
        mintSetup.adultMintCount += uint16(amount);
        adultMints[msg.sender] += amount;
        tokensMinted[msg.sender] +=amount;
        _safeMint(msg.sender, amount);
    }

    function mintForGenesis(uint amount, uint[] calldata tokenIds) external whenNotPaused notSoldOut {
        if(tokensMinted[msg.sender] + amount > maxMints) revert MintingTooMany();
        if(tokenIds.length != amount * genesisBurnsRequired) revert IncorrectGorillaCount();
        if(genesisMints[msg.sender] + amount > mintSetup.maxGenesisMintsPerPerson) revert MintingTooMany();
        if(mintSetup.genesisAdultMintCount + amount > mintSetup.maxGensisAdultMintCount) revert MintedOut();

        for(uint i; i < tokenIds.length; i++) {
            if(!isGenesis[tokenIds[i]]) revert WrongGorillaType();
        }

        transferCyber(cyberMintPrice * amount);
        burnBatchForOwner(tokenIds);
        mintSetup.genesisAdultMintCount += uint16(amount);
        genesisMints[msg.sender] += amount;
        tokensMinted[msg.sender] +=amount;
        _safeMint(msg.sender,amount);
        
    }

    /*///////////////////////////////////////////////////////////////
                          MINTING UTILITIES
    //////////////////////////////////////////////////////////////*/

    function transferCyber(uint amount) public {
        cyber.transferFrom(msg.sender,address(this),amount);
    }

    function burnForOwner(uint tokenId) internal {
        if(msg.sender != cyberGorillas.ownerOf(tokenId)) revert WrongOwner();
        cyberGorillas.burn(tokenId);
    }

    function burnBatchForOwner(uint[] calldata tokenIds) internal {
        for(uint i; i < tokenIds.length; i++){
            if(msg.sender != cyberGorillas.ownerOf(tokenIds[i])) revert WrongOwner();
            cyberGorillas.burn(tokenIds[i]);
        }
    }


    function teamMint(uint amount) public onlyOwner  notSoldOut{        
        require(teamMints + amount<=reservedForTeam,'Max Team Mints');
        teamMints += uint16(amount);
        _safeMint(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    function uploadGenesisArray(uint[] calldata tokenIds) external onlyOwner {
        for(uint i; i < tokenIds.length; i++) {
            isGenesis[tokenIds[i]] = true;
        }
    }

    function uploadWhitelist(address[] calldata accounts) external onlyOwner {
        for(uint i; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = true;
        }
    }



 
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setAdultBurnsRequired(uint amount) public onlyOwner {
        adultBurnsRequired = amount;
    }

    function setGenesisBurnsRequired(uint amount) public onlyOwner{
        genesisBurnsRequired = amount;
    }

    function setEthPrice(uint256 _newPrice) public onlyOwner {
        ethMintPrice = _newPrice;
    }
    function setMaxMints(uint newValue) external onlyOwner{
        maxMints = newValue;
    }

    function setCyberSupply(uint  _newCyberPrice) public onlyOwner{
        cyberMintPrice = _newCyberPrice;
    }

    function setCyberAddress(address _address) public onlyOwner{
        cyber = CyberToken(_address);
    }

    function setGorillaAddress(address _address) public onlyOwner{
        cyberGorillas = CyberGorilla(_address);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
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
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function burnCyber() public onlyOwner{
        uint balance = cyber.balanceOf(address(this));
        cyber.burn(balance);
    }

}



interface CyberToken{
    function transfer(address to, uint amount) external;
    function transferFrom(address from, address to, uint amount) external;
    function burn(uint amount) external;
    function balanceOf(address) external view returns(uint);
}

interface CyberGorilla {
    function ownerOf(uint tokenId) external view returns(address);
    function burn(uint tokenId) external;
}