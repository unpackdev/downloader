// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./console.sol";

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy { }
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract SOFA is ERC721, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;
  Counters.Counter private publicSupply;

  string mintURI;
  uint256 public mintCost = 0.5 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxPublicSupply = 900;
  

  // Max number of NFTs that can be minted at one time
  uint256 public maxMintAmount = 2;
  // max number of NFTs a wallet can mint/hold
  uint256 public nftPerAddressLimit = 2;
  
  address public openSeaProxyRegistryAddress;
  bool public isOpenSeaProxyActive = true;

  bool public pausedMint = true;

  mapping(address => uint256) public addressMintedBalance;

  constructor(
    string memory _name,
    string memory _symbol,
    address _openSeaProxyRegistryAddress,
    string memory _initMintURI
  ) ERC721(_name, _symbol) {
    mintURI = _initMintURI;
    openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
  }

  modifier mintCompliance(uint256 _mintAmount, bool _isPublicMint) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount!");
    // public mint
    if (_isPublicMint) {
      require(publicSupply.current() + _mintAmount <= maxPublicSupply, "Max supply exceeded!");
    }
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
  
  // public
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount, true) {
    require(!pausedMint, "the contract is paused");
    require(msg.value >= mintCost * _mintAmount);

    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
    
    _mintLoop(msg.sender, _mintAmount, true);
  }

  // Owner
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount, false) onlyOwner {
    _mintLoop(_receiver, _mintAmount, false);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount, bool _isPublicMint) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      if (_isPublicMint) {
        publicSupply.increment();
      }
      addressMintedBalance[_receiver]++;
      _safeMint(_receiver, supply.current());
    }
  }

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

    return mintURI;
  }

  function setMintCost(uint256 _newCost) external onlyOwner {
    mintCost = _newCost;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  function setMaxAddressNftLimit(uint256 _newMaxLimit) external onlyOwner {
    nftPerAddressLimit = _newMaxLimit;
  }

  function setMintURI(string memory _newMintURI) external onlyOwner {
    mintURI = _newMintURI;
  }

  // function to disable gasless listings for security in case
  // opensea ever shuts down or is compromised
  function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
      external
      onlyOwner
  {
      isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  function setOpenSeaProxyRegistryAddress(
        address _openSeaProxyRegistryAddress
    ) external onlyOwner {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

  function pauseMint(bool _state) external onlyOwner {
    pausedMint = _state;
  }

  function withdraw(uint256 _percentWithdrawl) public payable onlyOwner {
    require(address(this).balance != 0, "Balance is zero");
    require(_percentWithdrawl > 0 && _percentWithdrawl <= 100, "Withdrawl percent should be > 0 and <= 100");
    

    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance * _percentWithdrawl / 100}("");
    require(os);
    // =============================================================================
  }

  /**
    * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
    */
  function isApprovedForAll(address owner, address operator)
      public
      view
      override
      returns (bool)
  {
      // Get a reference to OpenSea's proxy registry contract by instantiating
      // the contract using the already existing address.
      ProxyRegistry proxyRegistry = ProxyRegistry(
          openSeaProxyRegistryAddress
      );
      if (
          isOpenSeaProxyActive &&
          address(proxyRegistry.proxies(owner)) == operator
      ) {
          return true;
      }

      return super.isApprovedForAll(owner, operator);
  }
}