//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Base64.sol";
import "./ERC721A.sol";
import "./Utils.sol";

contract BelleDAOphine is ERC721A, IERC2981, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string private baseURI = "https://gateway.pinata.cloud/ipfs/QmQGKAWMDmgef2UrCKDRTrZTUYiHRrcJb8Zs6rrKmeV7VT";
  address private openSeaProxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
  bool private isOpenSeaProxyActive = true;

  uint256 public constant MAX_MINTS_PER_TX = 20;
  uint256 public NUM_FREE_MINTS = 555;
  uint256 public MAX_SUPPLY = 1100;

  uint256 public constant PUBLIC_SALE_PRICE = 0.01 ether;
  bool public isPublicSaleActive = true;

  // ============ ACCESS CONTROL/SANITY MODIFIERS ============

  modifier publicSaleActive() {
    require(isPublicSaleActive, "Public sale is not open");
    _;
  }

  modifier maxMintsPerTX(uint256 numberOfTokens) {
    require(
      numberOfTokens <= MAX_MINTS_PER_TX,
      "Max mints per transaction exceeded"
    );
    _;
  }

  modifier canMintNFTs(uint256 numberOfTokens) {
    require(
      totalSupply() + numberOfTokens <= MAX_SUPPLY,
      "Not enough mints remaining to mint"
    );
    _;
  }

  modifier freeMintsAvailable() {
    require(
      totalSupply() <=
        NUM_FREE_MINTS,
      "Not enough free mints remain"
    );
    _;
  }

  modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
    if (totalSupply() > NUM_FREE_MINTS){
      require(
        (price * numberOfTokens) == msg.value,
        "Incorrect ETH value sent"
      );
    }
    _;
  }

  constructor() ERC721A("BelleDAOphine", "BELLE", 20, MAX_SUPPLY) {
  }

  // ============ PUBLIC FUNCTIONS FOR MINTING ============

  function mint(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
    publicSaleActive
    canMintNFTs(numberOfTokens)
    maxMintsPerTX(numberOfTokens)
  {
    _safeMint(msg.sender, numberOfTokens);
  }

    function freeMint(uint256 numberOfTokens)
      external
      nonReentrant
      publicSaleActive
      canMintNFTs(numberOfTokens)
      maxMintsPerTX(numberOfTokens)
      freeMintsAvailable()
    {
      _safeMint(msg.sender, numberOfTokens);
    }

  // ============ PUBLIC READ-ONLY FUNCTIONS ============

  function getBaseURI() external view returns (string memory) {
    return baseURI;
  }

  // ============ OWNER-ONLY ADMIN FUNCTIONS ============

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  // function to disable gasless listings for security in case
  // opensea ever shuts down or is compromised
  function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
    external
    onlyOwner
  {
    isOpenSeaProxyActive = _isOpenSeaProxyActive;
  }

  function setIsPublicSaleActive(bool _isPublicSaleActive)
    external
    onlyOwner
  {
    isPublicSaleActive = _isPublicSaleActive;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  // ============ FUNCTION OVERRIDES ============

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
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

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory output = string(abi.encodePacked(baseURI, "/", Utils.toString(tokenId), ".png"));

    string memory json = Base64.encode(
      bytes(
        string(
          // TODO BEFORE PROD DEPLOY - UPDATE DESCRIPTION
          abi.encodePacked(
            '{"name": "Belle DAOphine Pass #',
            Utils.toString(tokenId),
            '", "description": "Hi! This is BelleDAOphine <3 Welcome to my cute and weird lil world.. This is where you will find 1111 membership passes that wont be found anywhere else! I am so excited to share this silly, vulnerable, and magical journey with you.", "image": "',
            output,
            '"}'
          )
        )
      )
    );

    output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }

  /**
    * @dev See {IERC165-royaltyInfo}.
    */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");

    return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
  }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
