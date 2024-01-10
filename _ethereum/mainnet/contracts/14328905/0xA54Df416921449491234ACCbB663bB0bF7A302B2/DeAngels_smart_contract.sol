pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri ;
  
  uint256 public whiteListCost = 0.1 ether;
  uint256 public releaseCost = 0.15 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxMintAmount = 5;
  uint256 public nftPerAddressLimit = 5;
  
  address ownerWallet = 0xd9D61DE32508f15CCb4533Bbda6363f71e95996F;

  // hidden image url : ipfs://QmVEMfjD6Jg9LzXFumbo2h3vwUFeo6oxFNGeTSVsHeybAQ/hidden.json
  // initBaseUrl = ipfs://QmWHyGPRNyvqCSpxkmewnJDdS73pTgWzRKerRPyQ9B6MKP/
  // Simbol DANG
  // NAME DeAngels 

  uint whitelistStartDate = 1647003600;
  uint releaseDate = 1647014400;
  uint revealDate = 1647262800;

  bool public paused = false;
  
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //ipfs://QmWHyGPRNyvqCSpxkmewnJDdS73pTgWzRKerRPyQ9B6MKP/
  // 

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    require(isPresale() || isMintTime(), "Contract has not started");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");


    if (msg.sender != owner()) {
        if(isPresale()) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
        }

        require(msg.value >= getCost() * _mintAmount, "insufficient funds");
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
        _safeMint(msg.sender, supply + i);
    }
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

   function isPresale() public view returns (bool) {
       return block.timestamp > whitelistStartDate && block.timestamp < releaseDate;
  }

  function isMintTime() public view returns (bool) {
      return block.timestamp > releaseDate;
  }

  function getCost() public view returns (uint256) {
      return isPresale() ? whiteListCost : releaseCost;
  }

  function isRevield() public view returns (bool) {
      return block.timestamp > revealDate;
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
    
    if(!isRevield()) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setWhitelistCost(uint256 _newCost) public onlyOwner {
    whiteListCost = _newCost;
  }

  function setReleaseCost(uint256 _newCost) public onlyOwner {
    releaseCost = _newCost;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

  function setWhiteListStartDate(uint date) public onlyOwner {
    whitelistStartDate = date;
  }
  
  function setReleaseDate(uint date) public onlyOwner {
    releaseDate = date;
  }

  function setRevealDate(uint date) public onlyOwner {
    revealDate = date;
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
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }

  function setOwnerWallet(address _owner) public onlyOwner {
        ownerWallet = _owner;
  }


  function getOwnerWallet() public onlyOwner view returns (address) {
      return ownerWallet;
  }
 
  function withdraw() public payable onlyOwner {
    (bool hs, ) = payable(ownerWallet).call{value: address(this).balance}("");
    require(hs);
  }
}