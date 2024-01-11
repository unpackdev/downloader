// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract DesertIslandNFT is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  mapping(address => uint8) private _allowList;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public contractDataURI = "";
  address initialMintAddress;
  
  uint256 public presaleCost = 35000000000000000; // 0.035 ETH
  uint256 public cost = 40000000000000000; // 0.04 ETH
  uint256 public maxSupply = 5010;
  uint8 public maxMintAmountPerTx = 10;

  bool public paused = true;
  bool public presalePaused = true;

  constructor(
    string memory _uriPrefix,
    address _initialMintAddress,
    bool _presalePaused,
    string memory _contractDataURI
  ) ERC721("DesertIslandNFT", "DSTISL") {
    uriPrefix = _uriPrefix;
    initialMintAddress = _initialMintAddress;
    presalePaused = _presalePaused;
    contractDataURI = _contractDataURI;

    // Mint first 10 NFTs to the specified address
    for (uint8 i = 0; i < 10; i++) {
      supply.increment();
      _safeMint(initialMintAddress, supply.current());
    }
  }

  /*
    Helper modifier which check for correct mint amount passed & checks if the mint amount exceed max supply
  */
  modifier mintCompliance(uint8 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  /*
    Returns URL for contract metadata.
    For more information read this: https://docs.opensea.io/docs/contract-level-metadata
  */
  function contractURI() public view returns (string memory) {
    return contractDataURI;
  }

  /*
    Returns maximum supply of NFTs
  */
  function totalSupply() public view returns (uint256) {
    return maxSupply;
  }

  /* 
    Returns total supply of NFTs minted
  */
  function mintedSupply() public view returns (uint256) {
    return supply.current();
  }

  /*
    Returns current NFT price based on the whitelist sale status.
    Returns public mint price if whitelist sale is paused, otherwise whitelist mint price is returned.
  */
  function currentCost() public view returns (uint256) {
    if (!presalePaused) {
      return presaleCost;
    }

    return cost;
  }

  /*
    Allows to populate whitelist addresses and how much tokens they are able to mint.
    Can only be used by the owner
  */
  function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
        _allowList[addresses[i]] = numAllowedToMint;
    }
  }

  /* 
    Mint function, check if contract sale is currently open.
    Checks for the price. Formula: price * amount of NFTs
  */
  function mint(uint8 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused || !presalePaused, "The contract is paused!");

    if (!paused) {
      require(!paused, "Pre-sale is paused!");
      require(msg.value >= cost * _mintAmount, "Public sale: Insufficient funds!");

      _mintLoop(msg.sender, _mintAmount);
    }

    if (!presalePaused) {
      require(!presalePaused, "Pre-sale is paused!");
      require(_mintAmount <= _allowList[msg.sender], "Exceeded max available to purchase");
      require(msg.value >= presaleCost * _mintAmount, "Whitelist sale: Insufficient funds!");

      _allowList[msg.sender] -= _mintAmount;
      _mintLoop(msg.sender, _mintAmount);
    }
  }
  
  /* 
    Allows to mint NFTs for specific address, can only be used by the owner.
    Can only be used by the owner.
  */
  function mintForAddress(uint8 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  /*
    Returns token IDs owned by the address.
  */
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
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

  /*
    Returns complete token URI using prefix + token id + suffix.
  */
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
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  /*
    Allows to set new whitelist sale price.
    Can only be used by the owner.
  */
  function setPresaleCost(uint256 _cost) public onlyOwner {
      presaleCost = _cost;
  }

  /*
    Allows to set new public sale price.
    Can only be used by the owner.
  */
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  /* 
    Allows to set maximum numbers of NFTs that can be minted per tx.
    Can only be used by the owner.
  */
  function setMaxMintAmountPerTx(uint8 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  /*
    Allows to set new URI prefix.
    Can only be used by the owner.
  */
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  /*
    Allows to set new URI suffix.
    Can only be used by the owner.
  */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  /* 
    Toggle whitelist sale status.
    Can only be used by the owner.
  */
  function setPresalePaused(bool _state) public onlyOwner {
    presalePaused = _state;
  }

  /*
    Toggle public sale status.
    Can only be used by the owner.
  */
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  /*
    Withdraw contract balance to the caller's address.
    Can only be used by the owner.
  */
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  /*
    Mint function which allows to mint multiple tokens at the same time using loop.
  */
  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  /*
    Returns URI prefix which is currently set
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
