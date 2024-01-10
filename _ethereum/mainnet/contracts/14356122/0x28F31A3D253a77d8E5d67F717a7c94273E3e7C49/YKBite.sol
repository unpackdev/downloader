// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./Strings.sol";

/*

██    ██ ██   ██     ██████  ██ ████████ ███████
 ██  ██  ██  ██      ██   ██ ██    ██    ██
  ████   █████       ██████  ██    ██    █████
   ██    ██  ██      ██   ██ ██    ██    ██
   ██    ██   ██     ██████  ██    ██    ███████

                       Beauty In The Everyday

Contract by loltapes.eth
*/
contract YKBite is ERC721A, ERC2981, Ownable {
  using Strings for uint256;

  // Contract metadata
  string private contractUri;

  /* @dev baseURI for computing tokenURI */
  string public baseUri;

  /* @dev Address of the person to be able to mint */
  address public immutable ARTIST_ADDRESS;

  /* @dev Whether the airdrop photos were minted and distributed */
  bool public airdropComplete;

  /* @dev Whether the metadata was frozen */
  bool public metadataFrozen;

  address public immutable OS_PROXY_ADDRESS;

  /* @dev disable gasless listings for security in case OS is compromised */
  bool public isOpenSeaProxyDisabled;

  modifier whenMetadataNotFrozen {
    require(!metadataFrozen, "Metadata is frozen");
    _;
  }

  constructor(
    address _artistAddress,
    address _osProxyRegistryAddress,
    address _royaltySplitterAddress,
    string memory _baseUri,
    string memory _contractUri
  ) ERC721A("YK Beauty In The Everyday", "YKBITE") {
    ARTIST_ADDRESS = _artistAddress;
    OS_PROXY_ADDRESS = _osProxyRegistryAddress;
    baseUri = _baseUri;
    contractUri = _contractUri;

    // default 6.5% royalties
    _setDefaultRoyalty(_royaltySplitterAddress, 650);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function freezeMetadata()
  external
  onlyOwner
  whenMetadataNotFrozen
  {
    require(airdropComplete, "Airdrop not done");
    metadataFrozen = true;
  }

  function _baseURI()
  internal
  view
  virtual
  override
  returns (string memory) {
    return baseUri;
  }

  function setBaseUri(string memory _baseUri)
  external
  onlyOwner
  whenMetadataNotFrozen
  {
    baseUri = _baseUri;
  }

  function contractURI()
  public
  view
  returns (string memory)
  {
    return contractUri;
  }

  function setContractUri(string memory _contractUri)
  external
  onlyOwner
  whenMetadataNotFrozen
  {
    contractUri = _contractUri;
  }

  /* @notice Mint the predefined airdrop at once and distribute */
  function mintAirdrop(address[] calldata recipients)
  public
  {
    require(ARTIST_ADDRESS == msg.sender, "Restricted to artist");

    // can only mint the airdrop once
    require(!airdropComplete, "Airdrop already done");

    uint256 supply = recipients.length;

    // mint into artists wallet and transfer for provenance
    _safeMint(ARTIST_ADDRESS, supply);
    for (uint i = 0; i < supply; i++) {
      safeTransferFrom(ARTIST_ADDRESS, recipients[i], i + 1, '');
    }

    airdropComplete = true;
  }

  // disable gas-less listings in case OS wallet is compromised
  function setOpenSeaProxyDisabled(bool _isDisabled)
  external
  onlyOwner
  {
    isOpenSeaProxyDisabled = _isDisabled;
  }

  /*
   * Override to allow user's OpenSea proxy accounts to enable gas-free listings.
   */
  function isApprovedForAll(address _owner, address _operator)
  public
  view
  override
  returns (bool)
  {
    /* Support OpenSea Proxy for easy trading (Part 2) */
    OpenSeaProxyRegistry registry = OpenSeaProxyRegistry(OS_PROXY_ADDRESS);
    if (address(registry.proxies(_owner)) == _operator && !isOpenSeaProxyDisabled) return true;

    return super.isApprovedForAll(_owner, _operator);
  }

  // @notice Set token royalties
  // @param newRecipient recipient of the royalties
  // @param value points (using 2 decimals - 10_000 = 100, 0 = 0)
  function setRoyalties(address newRecipient, uint24 value)
  external
  onlyOwner
  {
    require(value <= 1000, "No more than 10% royalties");
    _setDefaultRoyalty(newRecipient, value);
  }

  // EIP2981 standard Interface return
  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC721A, ERC2981)
  returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

/* Support OpenSea Proxy for easy trading */
contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

/* Contract by loltapes.eth
          _       _ _
    ____ | |     | | |
   / __ \| | ___ | | |_ __ _ _ __   ___  ___
  / / _` | |/ _ \| | __/ _` | '_ \ / _ \/ __|
 | | (_| | | (_) | | || (_| | |_) |  __/\__ \
  \ \__,_|_|\___/|_|\__\__,_| .__/ \___||___/
   \____/                   | |
                            |_|
*/
