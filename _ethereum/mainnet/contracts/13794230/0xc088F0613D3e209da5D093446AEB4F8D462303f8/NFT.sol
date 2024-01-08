// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.033 ether;
  uint256 public maxSupply = 3;
  uint256 public maxMintAmount = 3;
  uint256 public nftPerAddressLimit = 3;
  uint256 public counter = 0;
  uint256 public limit = 20;
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public wave2Auth = false;
  address[] public pushWhitelist;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public wave2Counter;


//   address payable public payments;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
    // address _payments
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    // payments = payable(_payments);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    counter+=_mintAmount;

    require(counter <= limit, "The Current Minting Limit for this Wave has been reached");
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(pushisWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[msg.sender]++;
      if (wave2Auth == true)
      {
        wave2Counter[msg.sender]++;
        require(wave2Counter[msg.sender] <=1, "One Sloth Allowance for Wave 2");
      }
      
      _safeMint(msg.sender, supply + i);
    }
    
  }
  

  function startWave2() public onlyOwner()
  {
    wave2Auth = true;
  }

  function shutOffWave2() public onlyOwner()
  {
    wave2Auth = false;
  }

    function pushisWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < pushWhitelist.length; i++) {
      if (pushWhitelist[i] == _user) {
          return true;
      }
    }
    return false;
  }
  
  function refreshCounter() public onlyOwner()
  {
      counter = 0;
  }
  function setLimit(uint256 new_limit) public onlyOwner(){
    limit = new_limit;
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
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
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
  

    function pushToWhitelist(address []calldata _users) public onlyOwner {
    for(uint256 i=0; i<_users.length;i++){
      pushWhitelist.push(_users[i]);
  }
  }




 
  function withdraw() public payable onlyOwner {

    (bool mathieu, ) = payable(0x1EB3919eD6BE2c1C2809945F36a34E3c82e04C65).call{value: address(this).balance * 5 / 100}("");
    require(mathieu);
    (bool kiki, ) = payable(0x9b0aD5f28D54ffFc5ce74872cEE95FAfF85e0F89).call{value: address(this).balance * 442 / 1000}("");
    require(kiki);
    (bool farouk, ) = payable(0xF0b83F1E549BDd85c8aB87303341EF74d5748caC).call{value: address(this).balance * 1320 / 10000}("");
    require(farouk);
    (bool simon_ariel, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(simon_ariel);
    // (bool pay,) = payable(payments).call{value: address(this).balance}("");
    // require(pay);

  }
}