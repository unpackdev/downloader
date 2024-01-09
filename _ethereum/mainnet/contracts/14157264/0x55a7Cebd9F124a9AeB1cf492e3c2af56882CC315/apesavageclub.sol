//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract Ape_Savage_Club is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 10000;
  uint256 public nftPerAddressLimit = 15;
  bool public paused = true;
  bool public revealed = false;
  mapping(address => uint256) public addressMintedBalance;
  address payable private owner1 = payable(0xcc117590A434a1D451445042f9be784eB9053183 );
  address payable private owner2 = payable(0x2Bc6de156094bdac3773a9e42Cff70d4913a492C );
  address payable private owner3 = payable(0xBe91866cc9e751c286AD8042E3b46Ee0551d6Afc );
  constructor() ERC721("Ape Savage Club", "ASC") {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public mint
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the mint is paused");
    uint256 supply = totalSupply();
    //require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        require(addressMintedBalance[msg.sender] + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");
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
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
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
 
  function withdraw() external onlyOwner {
    uint part1 = address(this).balance / 100 * 25;
    uint part2 = address(this).balance / 100 * 25;
    uint part3 = address(this).balance / 100 * 50;
    owner1.transfer(part1);
    owner2.transfer(part2);
    owner3.transfer(part3);
    payable(owner()).transfer(address(this).balance);
  }
}