// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";



contract VipCardRoom is Ownable, ERC721A, ReentrancyGuard {
  event MintTransEvent(address indexed minter, uint256 value);

  event MintEvent(address indexed minter, string indexed note, uint256 value);

  event DevMintEvent(address indexed minter, string indexed note, uint256 value);

  event RefundIfOver(address indexed minter, string indexed note, uint256 value);

  //number of limited purchases per person
  uint256 public mintLimitPerAddress;
  //current period number of issue
  uint256 public issueAmount = 0;

  uint256 public mintedAmount = 0;

  bool private _whiteListCheck;

  uint256 public maxAmountForDevs;

  uint32 public issueNo;
  
  //配置
  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
  }


  SaleConfig public saleConfig;

  mapping(uint256 => bytes) private _tokenPayloads;

    // // metadata URI
  string private _baseTokenURI;

  address payable private _bankAccount;

  bytes32 public root;

  // address=>mapping(issueNo=>count)
  mapping(address => mapping(uint256 => uint256)) public whitelistMintCounter;

  string private _notRevealedURI;

  mapping(uint256 => bool) private _blindBoxOpened;

  // [issueNo]=seed
  mapping(uint256 => uint256) public seeds;
  mapping(uint256 => uint256) public dices;

  uint256 public issueStartTokenId;
  //[tokenId]=true
  mapping(uint256 => bool) public metadataOpened;
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 maxNormalNftIndex_,
    uint256 maxAmountForDevs_
  )  ERC721A("VCR", "VCR", maxBatchSize_, collectionSize_, maxNormalNftIndex_, maxAmountForDevs_) {
    require(maxNormalNftIndex_ <= collectionSize_,"larger collection size needed");

    mintLimitPerAddress = maxBatchSize_;
    maxAmountForDevs = maxAmountForDevs_;
    _bankAccount = payable(msg.sender);
  }

  function setIssueParam(uint256 issueStartTokenId_, uint64 mintlistPriceWei, uint32 publicSaleStartTime,uint256 mintMaxLimit,uint256 issueAmount_, uint32 issueNo_) 
    external 
    onlyOwner {
    require(issueAmount_ > 0, "issue amount must be nonzero");
    require(issueNo_ > 0, "issue No must be nonzero");
    require(issueStartTokenId_ >= totalSupply(), "issue start token must >= totalSupply");

    saleConfig = SaleConfig(
      publicSaleStartTime,
      mintlistPriceWei
    );

    mintLimitPerAddress = mintMaxLimit;
    issueAmount = issueAmount_;
    issueNo = issueNo_;
    mintedAmount = 0;

    issueStartTokenId = issueStartTokenId_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier isOpen() {
    require(
      issueNo > 0 
      && 
      issueAmount > 0 
      && 
      uint256(saleConfig.mintlistPrice) > 0
      &&
      uint256(saleConfig.publicSaleStartTime) > 0
      ,"issue param do not set all");
      _;
  }

  function mint(bytes32[] memory _proof, uint256 quantity) external payable isOpen callerIsUser {
    require(quantity > 0, "mint quantity must be nonzero");
    uint256 _saleStartTime = uint256(saleConfig.publicSaleStartTime);
    require(
      _saleStartTime != 0 && block.timestamp >= _saleStartTime,
      "sale has not started yet"
    );

    require(
      quantity <= maxBatchSize,
      "mint quantity more then maxBatchSize"
    );

    require(issueAmount > mintedAmount, "reached issue amount");

    uint256 price = uint256(saleConfig.mintlistPrice);
    require(price != 0, "nft sale has not begun yet");

    uint256 cost = price * quantity;
    require(cost <= msg.value, "ether must be enough");

    require((totalSupply() + quantity) <= maxNormalNftIndex, "reached max supply");

    if (_whiteListCheck) {
      require(_whitelistVerify(_proof), "Invalid merkle proof");
      require(whitelistMintCounter[msg.sender][issueNo] + quantity <= mintLimitPerAddress, "reached maxnot eligible for whitelist mint");
      whitelistMintCounter[msg.sender][issueNo] += quantity;
    }

    _safeMint(msg.sender, quantity, false);

    mintedAmount += quantity;

    _bankAccount.transfer(cost);
    emit MintTransEvent(_bankAccount, cost);
    emit MintEvent(msg.sender, "mint token success", quantity);

    _refundIfOver(cost);
  }

  function adminMint(uint256 quantity) external onlyOwner {
    require(quantity > 0, "adminMint quantity must be nonzero");

    require(issueAmount > mintedAmount, "reached issue amount");

    require((totalSupply() + quantity) <= maxNormalNftIndex, "reached max supply");

    _safeMint(msg.sender, quantity, false);

    mintedAmount += quantity;

    emit MintEvent(msg.sender, "adminMint token success", quantity);
  }

  function _refundIfOver(uint256 price) private {
    uint256 refundValue = msg.value - price;
    if (refundValue > 0) {
      payable(msg.sender).transfer(refundValue);
      emit RefundIfOver(msg.sender, "refund value", refundValue);
    }
  }

  function setMaxPerAddressDuringMint(uint256 val) external onlyOwner {
    require(val > 0, "maxPerAddressDuringMin must be above zero");
    mintLimitPerAddress = val;
  }

  // For marketing etc.
  function devMint(address to, uint256 quantity) external onlyOwner {
    require(to != address(0x0), "to address must be valied");
    require(
      leftAmountForDevs() >= quantity && quantity > 0,
      "too many already minted before dev mint"
    );

    _safeMint(to, quantity, true);

    emit DevMintEvent(msg.sender, "devMint token", quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function batchSetIssueTokensPayload(uint32[] memory tokenIds, bytes[] memory payloads) external onlyOwner {
    require(tokenIds.length == payloads.length, "tokenIds length must equals to payloads length");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _tokenPayloads[tokenIds[i]] = payloads[i];
    }
  }

  function setIssueTokenPayloadByTokenId(uint256 tokenId, bytes memory payload) external onlyOwner {
    if (_tokenPayloads[tokenId].length != 0x0) {
      _tokenPayloads[tokenId] = payload;
    }
  }

  function getTokenPayloadByTokenId(uint256 tokenId) public view returns(bytes memory) {
    return _tokenPayloads[tokenId];
  }

  /**
   * @dev
   * rand dice method depending on the issueNo, seed
   */
  function _random() private view returns(uint32) {
    uint256 random = uint256(keccak256(abi.encodePacked(issueNo, seeds[issueNo])));
    return uint32(random % issueAmount);
  }


  function setMerkleRoot(bytes32 _root, bool _check) external onlyOwner {
    root = _root;
    _whiteListCheck = _check;
  }

  function _whitelistVerify(bytes32[] memory _proof) internal view returns(bool) {
    return MerkleProof.verify(_proof, root, keccak256(abi.encodePacked(msg.sender)));
  }

  function setNotRevealedURI(string memory fn) external onlyOwner {
    _notRevealedURI = fn;
  }

  function setBlindBoxParams(bool open, uint256 _seed) external onlyOwner {
    _blindBoxOpened[issueNo] = open;
    seeds[issueNo] = _seed;
    dices[issueNo] = _random();
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
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

    string memory baseURI = _baseURI();
    if (_enableShowTokenName(tokenId)) {
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    } else {
      return bytes(_notRevealedURI).length > 0 ? _notRevealedURI : "";
    }
  }

  /**
   * @dev
   * show token metadata check
   */
  function _enableShowTokenName(uint256 tokenId) private view returns(bool){
    bool result = _blindBoxOpened[issueNo];
    return result ? result : metadataOpened[tokenId];
  }

  /**
   * @dev 
   * set metadataOpened
   */
  function setMetadataOpened(uint256[] memory tokenIds) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      metadataOpened[tokenIds[i]] = true;
    }
  }
}