// SPDX-License-Identifier: GPL-3.0

// Alecs CBS
/*

###############################################################################################
#################@@@@@@@@@@@@@@################################################################
###############@@             @@@@@@@@@@#######################################################
#############@@   @@@@@@@@@@             @@@####@@@@##@@@@@@######@@@##########################
#######@@@@@@   @            @     @        @@@@    @@      @@@@@@    @########################
######@       @    []    []   @  @   @         ,,,,,,                  @@@#####################
#####@      @      []    []   @  @     @     ,,      ,,                   @####################
########@@@@                  @    @@@@                        ,,,,,,      @################### 
##########@                 @                                ,,      ,,     @##################
#########@  [][][]        @                                                 @##################
#########@    []       @                                                      @################
###########@        @                                                          @###############
#############@@@@@@                                                            @###############  
################@                                                              @###############
################@        ,,        ,,                                         @################
################@          ,,,,,,,,                                          @#################
################@                                                            @#################
#################@                                     ,,,        ,,,        @#################
#################@                                        ,,,,,,,,          @##################
#################@                       @@@@@@@@@@@@            @@@@      @###################
###################@    @@@@@@    @@@@@@@############@@@@@@@    @###@    @#####################
###################@    @####@    @########################@    @###@    @#####################
###################@    @####@    @########################@    @###@    @#####################
###################@    @####@    @########################@    @###@    @#####################
###################@@@@@#####@@@@@@########################@@@@@@###@@@@@@#####################
###################@    @####@    @########################@    @###@    @#####################
###################@@@@@#####@@@@@##########################@@@@@####@@@@@#####################
###############################################################################################
###############################################################################################
###############################################################################################

                                    CryptoBleatingSheeps


*/
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";


contract CryptoBleatingSheeps is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public price = 0.08765 ether; // Price per Sheep
  uint256 public discountprice = 0.05 ether; // Discount Price for PartnerListed
  uint256 public maxSupply = 1234; // Total flock
  uint256 public maxMintAmount = 15; // Max mint per transaction
  uint256 public nftPerAddressLimit = 50; // Sheeps limit for address 
  bool public paused = false;
  bool public burnable = false;
  bool public revealed = true;
  bool public onlyWhitelisted = true;
  bool public onlyPartnerlisted = true;
  address[] public whitelistedAddresses;
  address[] public partnerListedAddresses;
  mapping(address => uint256) public addressMintedBalance;
  Counters.Counter private _tokenIds;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

   function burn(uint256 tokenId) 
        public 
        virtual 
    {
        require(burnable, "Burnable");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
  }


  function mint(uint256 _mintAmount) public payable {  // public check etherscan
    require(!paused, "Sale not active!");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, " Min 1 CBS");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max CBS per address exceeded");

        if(onlyWhitelisted == true ) {
            require(isWhitelisted(msg.sender), "address is not whitelisted");
        } 

        require(msg.value >= price * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }

  function mintPartner(uint256 _mintAmount) public payable {  // public check etherscan
    require(!paused, "Sale not active!");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, " Min 1 CBS");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max CBS per address exceeded");
        
        if(onlyPartnerlisted == true) {
            require(isPartnerlisted(msg.sender), "address is not Partnerlisted");
        }

        require(msg.value >= discountprice * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }


  function nft4owner(uint256 ownerToken)
        public onlyOwner      
    {
        _mint(owner(), ownerToken);
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function isPartnerlisted(address _user) public view returns (bool) {
    for (uint i = 0; i < partnerListedAddresses.length; i++) {
      if (partnerListedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
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
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setOnlyPartnerlist(bool _state) public onlyOwner {
    onlyPartnerlisted = _state;
  }
  
  
  function addWhitelistUsers(address[] calldata _users) public onlyOwner { //ARRAY users
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function addPartnerListUsers(address[] calldata _users) public onlyOwner { //ARRAY users
    delete partnerListedAddresses;
    partnerListedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
   function burnState(bool _state) public onlyOwner {
    burnable = _state;
  }
  
  
    // withdrawall addresses
  address t1 = 0xD7C358434D82046616E9A15045F6e36583eA6069; //Keyo
  address t2 = 0x878975Cf4a97774af6875B3B37b0920b83121F35; //Andre
  address t3 = 0x96F6a61a562f9c5194e3Ba25e45Db796a026e7cC; //Swissman
  address t4 = 0x32A2feA9F63feb642D76A2F0AB1e2948695f3820; //Alecs
  address t5 = 0xD87D856C6DEB338C099E4Fa5a81fAE9D6D6780c8; //Ste
  

  function withdrawall() public onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 _split = _balance / 5;

        require(payable(t1).send(_split));
        require(payable(t2).send(_split));
        require(payable(t3).send(_split));
        require(payable(t4).send(_split));
        require(payable(t5).send(_split));
  }
}