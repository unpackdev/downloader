// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract TheStreetCollectivePass is ERC721A, Ownable, ReentrancyGuard {
/*
███████╗████████╗██████╗ ███████╗███████╗████████╗  
██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝    
███████╗   ██║   ██████╔╝█████╗  █████╗     ██║       
╚════██║   ██║   ██╔══██╗██╔══╝  ██╔══╝     ██║       
███████║   ██║   ██║  ██║███████╗███████╗   ██║       
╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝      

 ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗██╗██╗   ██╗███████╗
██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██║██║   ██║██╔════╝
██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║██║   ██║█████╗  
██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║╚██╗ ██╔╝██╔══╝  
╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ██║ ╚████╔╝ ███████╗
 ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝
*/

  string public metadataUri;
  
  uint256 public cost; 
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  mapping(address => uint256) public mintCount;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setMetadataUri(_metadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) { 
    require(_currentIndex  + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(mintCount[msg.sender] < 1, "Can only mint once per wallet!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount , "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx , "Invalid mint amount!"); //no limit on mint amount for normal mints
    _mintLoop(msg.sender, _mintAmount);
    mintCount[msg.sender] += _mintAmount;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return currentBaseURI;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMetadataUri(string memory _metadataUri) public onlyOwner {
    metadataUri = _metadataUri;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      _safeMint(_receiver, _mintAmount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return metadataUri;
  }

}
