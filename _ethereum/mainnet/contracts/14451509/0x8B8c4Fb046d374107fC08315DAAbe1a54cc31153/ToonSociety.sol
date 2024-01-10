//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract ToonSociety is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIds;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedURI;
    string public mycontractURI;
    uint256 public cost = 0.12 ether;
    uint256 public maxSupply = 50;
    uint256 public maxMintAmount = 1;
    uint256 public nftPerAddressLimit = 1;
    uint96 royaltyBasis;
    bool public paused = false;
    bool public revealed = false;
    bool public onlyWhitelisted = true;
    address royaltyAddress;

    //Whitelist, Alpha, OG
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public addressMintedBalance;

    constructor(string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    uint96 _royaltyBasis, 
    string memory _contractURI) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        royaltyAddress = owner();
        royaltyBasis = _royaltyBasis;
        mycontractURI = _contractURI;
    }

    // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _notRevealedURI() internal view virtual returns (string memory) {
    return notRevealedURI;
  }

  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted[msg.sender], "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
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
        string memory currentNotRevealedURI = _notRevealedURI();
        return bytes(currentNotRevealedURI).length > 0
        ? string(abi.encodePacked(currentNotRevealedURI, Strings.toString(tokenId), baseExtension))
        : "";
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }

  function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(mycontractURI));
  }


  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view 
  returns (address receiver, uint256 royaltyAmount){
    return (royaltyAddress, _salePrice.mul(royaltyBasis).div(10000));
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable) returns (bool) {
      return interfaceId == type(IERC721Enumerable).interfaceId || 
      interfaceId == 0xe8a3d485 /* contractURI() */ ||
      interfaceId == 0x2a55205a /* ERC-2981 royaltyInfo() */ ||
      super.supportsInterface(interfaceId);
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setRoyaltyInfo(address _receiver, uint96 _royaltyBasis) public onlyOwner {
      royaltyAddress = _receiver;
      royaltyBasis = _royaltyBasis;
  }

  function setContractURI(string calldata _contractURI) public onlyOwner {
      mycontractURI = _contractURI;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
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
  
  function setNotRevealedURI(string memory _notRevealedUri) public onlyOwner {
    notRevealedURI = _notRevealedUri;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _onlyWhitelist) public onlyOwner() {
      onlyWhitelisted = _onlyWhitelist;
  }

  function addUsersToWhitelist(address[] memory _users) public onlyOwner {
    for(uint i=0;i<_users.length;i++)
      isWhitelisted[_users[i]] = true;
  }
  
  function addToWhitelist(address _user) public onlyOwner {
    isWhitelisted[_user] = true;
  }

  function removeFromWhitelist(address _user) public onlyOwner {
    isWhitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}
