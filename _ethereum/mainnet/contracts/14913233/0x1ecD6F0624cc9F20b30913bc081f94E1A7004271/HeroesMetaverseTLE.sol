// SPDX-License-Identifier: MIT
// Heroes of the Metaverse: The Last Essence

/* 
                                     WNXKNW
                                   WNKkxkKW
                                 WX0kxxx0N
                              WNKOxxxxx0W
                           WWNKOxxxxxx0W
                         WX0Okxxxxxxk0W
                      WNKOxxxxxxxxxkKW
                    WNKOxxxxxxxxxxkKW
                  WX0kxxxxxxxxxxxkKW
                NXOkxxxxxxxxxxxxkKW
             WNKOxxxxxxxxxxxxxxkKW
           WX0kxxxxxxxxxxxxxxxxk0KKKKKKKKKKKKKKKKXN
         WXOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkXW
      WNKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0NW
     N0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOKNW
    WXOkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxk0XW
      WWWWWWWWWWWWWWNNNXOxxxxxxxxxxxxxxxk0NW
                     WNOxxxxxxxxxxxxxxOKNW
                     NOxxxxxxxxxxxxk0XW
                    NOxxxxxxxxxxxk0XW
                   NOxxxxxxxxxxOKNW
                  XOxxxxxxxkkOXW
                WXOxxxxxxk0XNW
               WXOxxxxxOKNW
              WXOxxxkOKW
             WXkxxk0XW
             WKOOKNW
              WNNW
 */

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";

contract HeroesMetaverseTLE is ERC721A, Ownable, ReentrancyGuard, VRFConsumerBase {

  // Contract
  uint256 public immutable maxSupply;
  uint256 public immutable pricePerToken = 0.07 ether;
  string public constant provenance = "eaafaca161f3508ddafa27006834e0911d1dd932f36567f4b626cc138d3e8b0a";

  // Mint
  uint256 public constant amountPerMint = 3;
  uint256 public constant maxPresalePerWallet = 3;
  uint256 public constant maxTokensPerWallet = 9;

  // Token
  mapping(uint256 => string) gender;
  uint256 public offset;

  // Reservations
  uint256 public immutable reservedForDevs;
  uint256 public immutable reservedForProject; // MKT, gifts, givaways, etc
  uint256 public immutable maxBatchSize;
  bytes32 public whitelistRoot;
  mapping(address => uint256) public whitelistClaimed;

  // Operations
  string public baseURI;
  string private preRevealURI;
  bool public isPublicSaleOn = false;
  bool public isPresaleOn = false;
  bool public isGenderSwapOn = false;
  bool public revealed = false;
  address regentAddress;

  uint256 public chainlinkFee;
  bytes32 public chainlinkKeyHash;

  constructor(
    uint256 _maxSupply,
    uint256 _reservedForDevs,
    uint256 _reservedForProject,
    uint256 _maxBatchSize,
    string memory _preRevealURI,
    address _vrfCoordinator,
    address _linkAddress
  ) ERC721A("HeroesMetaverseTLE", "HOTM") VRFConsumerBase(_vrfCoordinator, _linkAddress) {
    require(_reservedForProject + _reservedForDevs <= _maxSupply, "HOTM.constructor: Max supply should be higher than reserved amounts");
    maxSupply = _maxSupply;
    reservedForDevs = _reservedForDevs;
    reservedForProject = _reservedForProject;
    maxBatchSize = _maxBatchSize;
    regentAddress = msg.sender;
    preRevealURI = _preRevealURI;
  }

  /* Modifiers */

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "HOTM.global: The caller is another contract");
    _;
  }

  modifier baseMintReq(uint256 _quantity) {
    uint256 minted = numberMinted(msg.sender);
    require(totalSupply() + _quantity <= maxSupply, "HOTM.mint: All heroes recruited");
    require(minted < maxTokensPerWallet, "HOTM.mint: Reached token limit per wallet");
    uint256 remainToLimit = maxTokensPerWallet - minted;
    require(_quantity <= remainToLimit, "HOTM.mint: Minting amount would exceed wallet limit, try fewer");
    require(_quantity <= amountPerMint, "HOTM.mint: Exceeded mint limit per transaction");
    _;
  }

  modifier priceReq(uint256 _quantity) {
    require(msg.value == pricePerToken * _quantity, "HOTM.mint: Wrong payment amount");
    _;
  }

  function _priceReq(uint256 _quantity) private priceReq(_quantity) {}

  function _baseMintReq(uint256 _quantity) private baseMintReq(_quantity) {}

  /* Minting */

  function mint(uint256 _quantity) external payable callerIsUser baseMintReq(_quantity) priceReq(_quantity) {
    require(isPublicSaleOn, "HOTM.mint: Public sale is not live");
    _safeMint(msg.sender, _quantity);
  }

  function presaleMint(uint256 _quantity, bytes32[] calldata _proof) external payable callerIsUser {
    require(isPresaleOn, "HOTM.presaleMint: Whitelist sale is not live");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, whitelistRoot, leaf), "HOTM.presaleMint: Address not whitelisted");
    require(whitelistClaimed[msg.sender] + _quantity <= maxPresalePerWallet, "HOTM.presaleMint: More than allowed during presale");
    _baseMintReq(_quantity);
    _priceReq(_quantity);

    whitelistClaimed[msg.sender] += _quantity;
    _safeMint(msg.sender, _quantity);
  }

  function numberMinted(address _owner) public view returns (uint256) {
    return _numberMinted(_owner);
  }

  function devMint(uint256 _quantity) external onlyOwner {
    require(totalSupply() + _quantity <= maxSupply, "HOTM.mint: All heroes recruited");
    require(_quantity % maxBatchSize == 0, "HOTM.devMint: Can only mint a multiple of the maxBatchSize");
    uint256 numChunks = _quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  /* Operations */

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    whitelistRoot = _merkleRoot;
  }

  function setBaseURI(string calldata baseUri_) external onlyOwner {
    baseURI = baseUri_;
  }

  function _baseURI() internal view override(ERC721A) returns (string memory) {
    return baseURI;
  }

  function setPresaleOn(bool _isOn) external onlyOwner {
    isPresaleOn = _isOn;
  }

  function setPublicSaleOn(bool _isOn) external onlyOwner {
    isPublicSaleOn = _isOn;
  }

  function setGenderSwapOn(bool _isOn) external onlyOwner {
    isGenderSwapOn = _isOn;
  }

  /* Reveal Operations */
  function setChainlinkConfig(uint256 _fee, bytes32 _keyhash) external onlyOwner {
    chainlinkFee = _fee;
    chainlinkKeyHash = _keyhash;
  }

  function startReveal(string memory baseUri_) external onlyOwner returns (bytes32 requestId) {
    require(!revealed, "HOTM.Reveal: Already Revealed");
    baseURI = baseUri_;
    return requestRandomness(chainlinkKeyHash, chainlinkFee);
  }

  function fulfillRandomness(bytes32, uint256 _randomness) internal override {
    require(!revealed, "HOTM.Reveal: Already Revealed");
    revealed = true;
    offset = _randomness % maxSupply;
  }

  function withdraw() public onlyOwner nonReentrant {
    if (regentAddress != owner()) {
      payable(regentAddress).transfer((address(this).balance * 1) / 100);
    }
    payable(msg.sender).transfer(address(this).balance);
  }

  function setRegent(address _regentAddress) public onlyOwner nonReentrant {
    require(_regentAddress != regentAddress, "HOTM.setRegent: No regent rules forever");
    regentAddress = _regentAddress;
  }

  function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
    return 1;
  }

  /* Hero Operations */

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
    if (!revealed) return preRevealURI;
    string memory baseUri_ = _baseURI();
    uint256 shiftedTokenId = getShiftedToken(_tokenId);
    return
      bytes(baseUri_).length != 0
        ? string(abi.encodePacked(baseUri_, getGender(shiftedTokenId), "_", Strings.toString(shiftedTokenId), ".json"))
        : "";
  }

  function getShiftedToken(uint256 _tokenId) public view returns (uint256) {
    return (_tokenId + offset) % maxSupply;
  }

  function compareStrings(string memory a, string memory b) public pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  function toggleGender(uint256 tokenId) external {
    require(isGenderSwapOn, "HOTM.toggleGender: Gender swap is not live");
    require(ownerOf(tokenId) == _msgSender(), "HOTM.toggleGender: You are not the owner");

    gender[tokenId] = compareStrings(getGender(tokenId), "male") ? "female" : "male";
  }

  function getGender(uint256 tokenId) public view returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    return bytes(gender[tokenId]).length != 0 ? gender[tokenId] : "male";
  }
}
