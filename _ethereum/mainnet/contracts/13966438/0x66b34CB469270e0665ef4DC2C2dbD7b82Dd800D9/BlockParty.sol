// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract BlockParty is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  using Strings for uint256;

  constructor(
    address baseFactory,
    string memory customBaseURI_,
    address accessTokenAddress_,
    address proxyRegistryAddress_
  )
    ERC721Delegated(
      baseFactory,
      "BlockParty",
      "BKPT",
      ConfigSettings({
        royaltyBps: 1000,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {
    accessTokenAddress = accessTokenAddress_;

    proxyRegistryAddress = proxyRegistryAddress_;

    allowedMintCountMap[msg.sender] = 1;

    allowedMintCountMap[0x7c228e74D601Ee9414277a674ABf9b58950E87CC] = 1;
  }

  /** TOKEN PARAMETERS **/

  struct TokenParameters {
    uint256 seed;
    uint256 speed;
    uint256 elevation;
  }

  mapping(uint256 => TokenParameters) private tokenParametersMap;

  function tokenParameters(uint256 tokenId) external view
    returns (TokenParameters memory)
  {
    return tokenParametersMap[tokenId];
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  function allowedMintCount(address minter) public view returns (uint256) {
    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  address public immutable accessTokenAddress;

  uint256 public constant MAX_SUPPLY = 200;

  uint256 public constant MAX_MULTIMINT = 20;

  uint256 public constant PRICE = 50000000000000000;

  Counters.Counter private supplyCounter;

  function mint(uint256[] calldata ids, TokenParameters[] calldata parameters)
    public
    payable
    nonReentrant
  {
    uint256 count = ids.length;

    if (!saleIsActive) {
      if (allowedMintCount(msg.sender) >= count) {
        updateMintCount(msg.sender, count);
      } else {
        revert("Sale not active");
      }
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 20 at a time");

    require(
      msg.value >= PRICE * count, "Insufficient payment, 0.05 ETH per item"
    );

    IERC721 accessToken = IERC721(accessTokenAddress);

    for (uint256 i = 0; i < count; i++) {
      uint256 id = ids[i];

      require(accessToken.ownerOf(id) == msg.sender, "Access token not owned");

      _mint(msg.sender, id);

      tokenParametersMap[id] = parameters[i];

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    TokenParameters memory parameters = tokenParametersMap[tokenId];

    return (
      string(
        abi.encodePacked(
          _tokenURI(tokenId),
          "?",
          "seed=",
          parameters.seed.toString(),
          "&",
          "speed=",
          parameters.speed.toString(),
          "&",
          "elevation=",
          parameters.elevation.toString()
        )
      )
    );
  }

  /** PAYOUT **/

  address private constant payoutAddress1 =
    0x7c228e74D601Ee9414277a674ABf9b58950E87CC;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance * 50 / 100);

    Address.sendValue(payable(payoutAddress1), balance * 50 / 100);
  }

  /** PROXY REGISTRY **/

  address private immutable proxyRegistryAddress;

  function isApprovedForAll(address owner, address operator) public view
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return _isApprovedForAll(owner, operator);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so