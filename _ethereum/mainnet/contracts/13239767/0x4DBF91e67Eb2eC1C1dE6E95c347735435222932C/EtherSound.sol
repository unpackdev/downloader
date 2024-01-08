// SPDX-License-Identifier: MIT

/**

 ________  __      __                             ______                                       __ 
/        |/  |    /  |                           /      \                                     /  |
$$$$$$$$/_$$ |_   $$ |____    ______    ______  /$$$$$$  |  ______   __    __  _______    ____$$ |
$$ |__  / $$   |  $$      \  /      \  /      \ $$ \__$$/  /      \ /  |  /  |/       \  /    $$ |
$$    | $$$$$$/   $$$$$$$  |/$$$$$$  |/$$$$$$  |$$      \ /$$$$$$  |$$ |  $$ |$$$$$$$  |/$$$$$$$ |
$$$$$/    $$ | __ $$ |  $$ |$$    $$ |$$ |  $$/  $$$$$$  |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
$$ |_____ $$ |/  |$$ |  $$ |$$$$$$$$/ $$ |      /  \__$$ |$$ \__$$ |$$ \__$$ |$$ |  $$ |$$ \__$$ |
$$       |$$  $$/ $$ |  $$ |$$       |$$ |      $$    $$/ $$    $$/ $$    $$/ $$ |  $$ |$$    $$ |
$$$$$$$$/  $$$$/  $$/   $$/  $$$$$$$/ $$/        $$$$$$/   $$$$$$/   $$$$$$/  $$/   $$/  $$$$$$$/ 
                         
Each EtherSound is a set of 8 random C major notes ranging from C2 to B4.
First 777 EtherSounds can be claimed if your Eth balance < 1 Eth and EtherSounds balance < 10 EtherSounds.
Otherwhise you can still mint them.

Mint price : 0.05 Eth                                                                                                  
Max mint : 10 EtherSounds
Supply : 7777 EtherSounds

*/

pragma solidity ^0.8.0;


import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract EtherSound is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 7777;
  uint256 public maxSupplyClaim = 777;
  uint256 public maxMintAmount = 10;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
     
    setBaseURI(_initBaseURI);
   
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function claim(uint256 _claimAmount) public nonReentrant {
    uint256 supply = totalSupply();
    require(msg.sender.balance < 1 * 10**18);
    require(balanceOf(msg.sender) + _claimAmount <= 10);
    require(_claimAmount > 0);
    require(_claimAmount <= maxMintAmount);
    require(supply + _claimAmount <= maxSupplyClaim);
    
    for (uint256 i = 1; i <= _claimAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  } 

  function mint(uint256 _mintAmount) public payable nonReentrant {
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(msg.value >= cost * _mintAmount);

    for (uint256 i = 1; i <= _mintAmount; i++) {
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function PleaseReadTheCode() public payable{
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}