// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";
// import "./console.sol";

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy { }
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract HonoraryCroc is ERC721, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 100;
  
  // Max number of NFTs that can be minted at one time
  uint256 public maxMintAmount = 5;
  
  address public openSeaProxyRegistryAddress;
  bool public isOpenSeaProxyActive = true;

  constructor(
    string memory _name,
    string memory _symbol,
    address _openSeaProxyRegistryAddress,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    baseURI = _initBaseURI;
    openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }
  
  // Owner
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
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