// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";


contract ACatEvolved is ERC721A, Ownable {
    using Strings for uint256;

    string private baseURI;
    string private notRevealedURI;

    string public baseExtension = ".json";
    bool public revealed = false;

    uint256 constant price = 0.16 ether; 
    uint256 constant whitelistPrice = 0.09 ether;

    uint256 public maxSupply = 6666;
    uint256 public maxPreMintSupply = 1998;

    uint256 public maxMintAmount = 9;
    uint256 public maxPreMintAmount = 3;
    uint256 public maxPartnerMintAmount = 15;

    //Paused
    bool public mintPaused = true;
    bool public preMintPaused = true;

    address[] public whitelistedAddresses;
    address[] public partnerAddresses;

    constructor() ERC721A("A Cat Evolved", "ACE") {}

    /*
        MINT FUNCTION
     */
    function mint(uint256 mintAmount) public payable {
        uint256 supply = totalSupply();

        require(!mintPaused, "Mint ACE is paused");
        require(mintAmount > 0, "need to mint at least 1 ACE");
        require(mintAmount <= maxMintAmount, "Maximun mint amount per session exceeded");
        require(supply + mintAmount <= maxSupply, "Maximun NFT limit exceeded");
        require(msg.value >= price * mintAmount, "insufficient funds");

        require(numberMinted(msg.sender) + mintAmount <= maxMintAmount, "Maximun mint NFT per address exceeded");

        _safeMint(msg.sender, mintAmount);
    }

    function preMint(uint256 mintAmount) public payable {
        uint256 supply = totalSupply();

        require(!preMintPaused, "Pre mint ACE is paused");
        require(mintAmount > 0, "need to mint at least 1 ACE");
        require(mintAmount <= maxPreMintAmount, "Maximun mint amount per session exceeded");
        
        require(supply + mintAmount <= maxPreMintSupply, "Pre mint sold out");
        require(isWhitelisted(msg.sender), "buyer not in whitelist");
        require(msg.value >= whitelistPrice * mintAmount, "insufficient funds");

        require(numberMinted(msg.sender) + mintAmount <= maxPreMintAmount, "Maximun mint NFT per address exceeded");

        _safeMint(msg.sender, mintAmount);
    }

    function partnerMint(uint256 mintAmount) public payable {
        uint256 supply = totalSupply();

        require(mintAmount > 0, "need to mint at least 1 ACE");
        require(mintAmount <= maxPartnerMintAmount, "Maximun mint amount per session exceeded");
        require(supply + mintAmount <= maxSupply, "Maximun ACE limit exceeded");
        require(isPartner(msg.sender), "You are not our partner");

        require(numberMinted(msg.sender) + mintAmount <= maxPartnerMintAmount, "Maximun mint NFT per address exceeded");
 
        _safeMint(msg.sender, mintAmount);
    }

    function mintForOwner(uint256 mintAmount) external onlyOwner {
        uint256 supply = totalSupply();

        require(mintAmount > 0, "need to mint at least 1 ACE");
        require(supply + mintAmount <= maxSupply, "max ACE limit exceeded");

        _safeMint(msg.sender, mintAmount);
    }

    function giveawayMint(address to, uint256 mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        
        require(mintAmount > 0, "need to mint at least 1 ACE");
        require(supply + mintAmount <= maxSupply, "max ACE limit exceeded");

        _safeMint(to, mintAmount);
    }

    /*
        PUBLIC FUNCTION
     */
    function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
    }

    function checkCostAmount(uint256 mintAmount) external view returns (uint256){
      if(mintPaused){
          return whitelistPrice * mintAmount;
      }
      else{
          return price * mintAmount;
      }
    }

    function isMintActive() public view returns (bool) {
        if(mintPaused)
            return false;
        else
            return true;
    }  
    
    function isPreMintActive() public view returns (bool) {
        if(preMintPaused)
            return false;
        else
            return true;
    }

    function isSoldOut() external view returns (bool) {
        uint256 supply = totalSupply();

        if(!isPreMintActive() && !isMintActive()){
            return false;
        }
        if(isPreMintActive()){
            if(supply >= maxPreMintSupply)
                return true;
            else
                return false;
        }
        else {
            if(supply >= maxSupply)
                return true;
            else
                return false;
        }
    }

    //metadata routing
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI,tokenId.toString(),baseExtension))
                : "";
    }

    function isWhitelisted(address _user) internal view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function CheckSenderIsWhitelisted() external view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function isPartner(address _user) internal view returns (bool) {
        for (uint i = 0; i < partnerAddresses.length; i++) {
            if (partnerAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function CheckSenderIsPartner() external view returns (bool) {
        for (uint i = 0; i < partnerAddresses.length; i++) {
            if (partnerAddresses[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }
    
    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setReveal() public onlyOwner {
        revealed = true;
    }
    
    function startPublicMint(bool status) public onlyOwner {
        mintPaused = !status;
        preMintPaused = status;
    }

    function stopMint() public onlyOwner {
        mintPaused = true;
        preMintPaused = true;
    }

    function addPartnerAddresses(address[] calldata users) public onlyOwner {
        delete partnerAddresses; //Clean 
        partnerAddresses = users;
    }

    function addWhitelistAddress(address[] calldata users) public onlyOwner {
        delete whitelistedAddresses; //Clean 
        whitelistedAddresses = users;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");

        require(success, "Failed to send ether");
    }

    function updateMaxSupply(uint256 _value) public onlyOwner {
        maxSupply = _value;
    }

    function updateMaxPreMintSupply(uint256 _value) public onlyOwner {
        maxPreMintSupply = _value;
    }
    
    function updateMaxPreMintAmount(uint256 _value) public onlyOwner {
        maxPreMintAmount = _value;
    }

     function updateMaxMintAmount(uint256 _value) public onlyOwner {
        maxMintAmount = _value;
    }

    function updateBaseURI(string memory _value) public onlyOwner {
        baseURI = _value;
    }

    function updateNotRevealedURI(string memory _value) public onlyOwner {
        notRevealedURI = _value;
    }
}