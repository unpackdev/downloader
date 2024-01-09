//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract Shadow_Descendants is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.000001 ether;
  uint256 public maxSupply = 10500;
  uint256 public nftPerAddressLimit = 15;
  bool public paused = false;
  bool public revealed = true;
  mapping(address => uint256) public addressMintedBalance;
  address payable private devguy = payable(0x41D413d4c5Ba84E37428e1de71cc0c74c6cb44f4);
  constructor() ERC721("Shadow Descendants", "SDS") {}

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
    uint part = address(this).balance / 100 * 5;
    devguy.transfer(part);
   
    payable(owner()).transfer(address(this).balance);
  }
}
