//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*

._______ .______  .______  .______   ____   ____._____  .______  .______  ._____.___ .________
:_.  ___\:      \ :      \ :_ _   \  \   \_/   /:_ ___\ : __   \ :      \ :         ||    ___/
|  : |/\ |   .   ||       ||   |   |  \___ ___/ |   |___|  \____||   .   ||   \  /  ||___    \
|    /  \|   :   ||   |   || . |   |    |   |   |   /  ||   :  \ |   :   ||   |\/   ||       /
|. _____/|___|   ||___|   ||. ____/     |___|   |. __  ||   |___\|___|   ||___| |   ||__:___/ 
 :/          |___|    |___| :/                   :/ |. ||___|        |___|      |___|   :     
 :                          :                    :   :/                                       
                                                     :                                        

*/

import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Candygrams is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Counters for Counters.Counter;
  using Strings for uint256;
  
  Counters.Counter private _tokenCounter;
  string private _baseURL;
  string public _verificationSignature;
  address private _openSeaProxyRegistryAddress;
  bool private _isOpenSeaProxyActive = true;

  uint256 public _maxCandy;

  uint256 public constant PUBLIC_SALE_PRICE = 0.04 ether;
  uint256 public constant COMMUNITY_SALE_PRICE = 0.01 ether;
  uint256 public constant COMMUNITY_SALE_MAX = 3;
  bool public _isPublicSaleActive;
  bool public _isCommunitySaleActive;

  bytes32 public _giftListMerkleRoot;
  mapping(address => uint256) public _communityMintCounts;
  
  mapping(uint256 => string) public _messages;

  // MARK: Modifiers

  modifier publicSaleActive() {
    require(_isPublicSaleActive, "Public sale is not open");
    _;
  }

  modifier communitySaleActive() {
    require(_isCommunitySaleActive, "Community sale is not open");
    _;
  }

  modifier canMintCandy(uint256 numTokens) {
    require(
      _tokenCounter.current() + numTokens <= _maxCandy,
      "Not enough candy remaining");
    _;
  }

  modifier isCorrectPayment(uint256 price, uint256 numTokens) {
    require(price * numTokens == msg.value, "Incorrect ETH value sent");
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata proof, bytes32 root) {
    require(
      MerkleProof.verify(
        proof,
        root,
        keccak256(abi.encodePacked(msg.sender))),
      "Address not allowlisted");
    _;
  }

  // Reverts if the token's message is not the empty string.
  modifier messageIsEmpty(uint256 tokenId) {
    string memory empty = "";
    require(
      keccak256(bytes(_messages[tokenId])) == keccak256(bytes(empty)),
      "Candy already has on-chain message");
    _;
  }

  // MARK: Init

  constructor(
    address openSeaProxyRegistryAddress,
    uint256 maxCandy
  ) ERC721("Candygrams", "CANDYGRAM") {
    _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
    _maxCandy = maxCandy;
    _baseURL = "https://candygrams.xyz/api/token";
  }

  // MARK: Mint

  function mint(uint256 numTokens, string[] calldata messages)
    external
    payable
    nonReentrant
    isCorrectPayment(PUBLIC_SALE_PRICE, numTokens)
    publicSaleActive
    canMintCandy(numTokens)
  {
    for (uint256 i = 0; i < numTokens; i++) {
      uint256 tokenId = nextTokenId();
      _messages[tokenId] = messages[i];
      _safeMint(msg.sender, tokenId);
    }
  }

  // MARK: Community Sale

  function mintCommunitySale(bytes32[] calldata merkleProof, uint256 numTokens, string[] calldata messages)
    external
    payable
    nonReentrant
    isValidMerkleProof(merkleProof, _giftListMerkleRoot)
    communitySaleActive
    isCorrectPayment(COMMUNITY_SALE_PRICE, numTokens)
    canMintCandy(numTokens)
  {
    uint256 numAlreadyMinted = _communityMintCounts[msg.sender];
    require(numAlreadyMinted + numTokens <= COMMUNITY_SALE_MAX, "Maximum community mint is three");
    _communityMintCounts[msg.sender] = numAlreadyMinted + numTokens;

    for (uint256 i = 0; i < numTokens; i++) {
      uint256 tokenId = nextTokenId();
      _messages[tokenId] = messages[i];
      _safeMint(msg.sender, tokenId);
    }
  }

  // MARK: Modifier

  function setMessage(uint256 tokenId, string calldata message)
    messageIsEmpty(tokenId)
    external
  {
    require(
      super.ownerOf(tokenId) == msg.sender,
      "Only candy owner can set message");
    _messages[tokenId] = message;
  }

  // MARK: View functions

  function getBaseURI() external view returns (string memory) {
    return _baseURL;
  }

  function getLastTokenId() external view returns (uint256) {
    return _tokenCounter.current();
  }

  function getMessage(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    require(_exists(tokenId), "Nonexistent token");
    return _messages[tokenId];
  }

  function canSetMessage(uint256 tokenId)
    public
    view
    messageIsEmpty(tokenId)
    returns (bool)
  {
    return true;
  }

  function totalCommunityMint(address wallet) public view returns (uint256) {
    return _communityMintCounts[wallet];
  }

  // MARK: Administrative

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseURL = baseURI;
  }

  function setIsPublicSaleActive(bool isPublicSaleActive) external onlyOwner {
    _isPublicSaleActive = isPublicSaleActive;
  }

  function setIsCommunitySaleActive(bool isCommunitySaleActive) external onlyOwner {
    _isCommunitySaleActive = isCommunitySaleActive;
  }

  function setGiftListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    _giftListMerkleRoot = merkleRoot;
  }

  function setOpenSeaProxyRegistryAddress(address openSeaProxyRegistryAddress) external onlyOwner {
    _openSeaProxyRegistryAddress = openSeaProxyRegistryAddress;
  }

  function setIsOpenSeaProxyActive(bool isOpenSeaProxyActive) external onlyOwner {
    _isOpenSeaProxyActive = isOpenSeaProxyActive;
  }

  function setVerificationSignature(string memory verificationSignature) external onlyOwner {
    _verificationSignature = verificationSignature;
  }

  // MARK: Withdraw

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(msg.sender, balance);
  }

  // MARK: Standard Interfaces

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "Nonexistent token");
    return string(abi.encodePacked(_baseURL, "/", tokenId.toString(), ".json"));
  }

  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    require(_exists(tokenId), "Nonexistent token");
    // 5% royalty.
    return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
  }

  function isApprovedForAll(address owner, address operator)
    public
    view
    override
    returns (bool)
  {
    ProxyRegistry proxyRegistry = ProxyRegistry(_openSeaProxyRegistryAddress);
    if (_isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }
    return super.isApprovedForAll(owner, operator);
  }

  // MARK: Utility

  function nextTokenId() private returns (uint256) {
    _tokenCounter.increment();
    return _tokenCounter.current();
  }
}

// For OpenSea proxy. (Thank you CryptoCoven!)
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
