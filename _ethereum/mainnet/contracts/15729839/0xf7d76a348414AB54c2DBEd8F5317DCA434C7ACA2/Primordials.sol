//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./IERC721A.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract Primordials is ERC721A, Ownable, VRFConsumerBaseV2 {
  using Strings for uint256;

  event SupplyUpdate(uint256 totalSupplyValue);

  enum SaleState {
    CLOSED,
    WHITELIST,
    ALLOWLIST,
    PUBLIC
  }

  enum ContractType {
    ERC20,
    ERC721,
    ERC721A
  }

  struct AllowedContract {
    address tokenContractAddress;
    uint256 MIN_HOLDING;
    ContractType tokenType;
  }

  struct Batch {
    uint256 requestId;
    uint256 seed;
    uint256 until;
  }

  uint64 public link_subscriptionId;
  uint256 public constant MAX_SUPPLY = 5555;
  uint256 public constant MAX_MINT_PER_TXN = 10;
  uint256 public constant MAX_WHITELIST_MINT = 10;
  uint256 public constant MAX_ALLOWLIST_MINT = 10;
  uint256 public constant MAX_TEAM_MINT = 20;
  uint256 public constant ALLOWLIST_SALE_PRICE = 0.055 ether;
  uint256 public constant WHITELIST_SALE_PRICE = 0.055 ether;
  uint256 public constant PUBLIC_SALE_PRICE = 0.065 ether;

  string internal baseExtension = '.json';
  string private baseTokenUri;
  string private placeholderTokenUri;

  bool public teamMinted;
  bool public link_requestPending;

  bytes32 private merkleRoot;

  mapping(address => uint256) public totalWhitelistMint;
  mapping(address => uint256) public totalAllowlistMint;
  mapping(address => uint256) public totalPublicMint;

  uint256 public revealTime;

  SaleState public saleState = SaleState.CLOSED;

  Batch[] batches;

  AllowedContract[] allowedContracts;

  VRFCoordinatorV2Interface LINK_COORDINATOR;

  constructor(address _vrfCoordinator, uint64 _subscriptionId)
    ERC721A('Primordials', 'PRIML')
    VRFConsumerBaseV2(_vrfCoordinator)
  {
    LINK_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    link_subscriptionId = _subscriptionId;

    allowedContracts.push(
      AllowedContract(
        0x657B83A0336561C8f64389a6f5aDE675C04b0C3b,
        50,
        ContractType.ERC20
      ) // pcnt token
    );
  }

  modifier mintQCheck(uint256 _quantity) {
    require(_quantity > 0, 'Primordials :: Mint quantity cannot be zero');
    require(
      _quantity <= MAX_MINT_PER_TXN,
      'Primordials :: Exceed MAX_MINT_PER_TXN'
    );
    require(
      (totalSupply() + _quantity) <= MAX_SUPPLY,
      'Primordials :: Exceed MAX_SUPPLY'
    );
    _;
  }

  modifier callerIsUser() {
    require(
      tx.origin == msg.sender,
      'Primordials :: Cannot be called by a contract'
    );
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenUri;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function teamMint() public onlyOwner {
    require(!teamMinted, 'Primordials :: Team already minted');
    teamMinted = true;
    _safeMint(0xD5E815183EcDAbe1B0780e2332BBB39527885B44, MAX_TEAM_MINT / 2);
    _safeMint(0xA6922fFB1d2Ee77d1e2758f1Ca437Da91442F6BC, MAX_TEAM_MINT / 2);
    emit SupplyUpdate(totalSupply());
  }

  function whitelistVerify(bytes32[] memory _merkleProof)
    public
    view
    returns (bool)
  {
    return
      MerkleProof.verify(
        _merkleProof,
        merkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      );
  }

  function allowedContractHoldingVerify(address sender)
    public
    view
    returns (bool)
  {
    for (uint256 i = 0; i < allowedContracts.length; i++) {
      if (allowedContracts[i].tokenType == ContractType.ERC20) {
        IERC20 _TOKEN_CONTRACT = IERC20(
          allowedContracts[i].tokenContractAddress
        );

        if (
          _TOKEN_CONTRACT.balanceOf(sender) >= allowedContracts[i].MIN_HOLDING
        ) {
          return true;
        } else continue;
      } else if (allowedContracts[i].tokenType == ContractType.ERC721A) {
        IERC721A _TOKEN_CONTRACT = IERC721A(
          allowedContracts[i].tokenContractAddress
        );

        if (
          _TOKEN_CONTRACT.balanceOf(sender) >= allowedContracts[i].MIN_HOLDING
        ) {
          return true;
        } else continue;
      } else if (allowedContracts[i].tokenType == ContractType.ERC721) {
        IERC721 _TOKEN_CONTRACT = IERC721(
          allowedContracts[i].tokenContractAddress
        );

        if (
          _TOKEN_CONTRACT.balanceOf(sender) >= allowedContracts[i].MIN_HOLDING
        ) {
          return true;
        } else continue;
      } else {
        continue;
      }
    }
    return false;
  }

  function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity)
    external
    payable
    callerIsUser
    mintQCheck(_quantity)
  {
    require(
      saleState == SaleState.WHITELIST,
      'Primordials :: WHITELIST is closed'
    );
    require(
      (totalWhitelistMint[msg.sender] + _quantity) <= MAX_WHITELIST_MINT,
      'Primordials :: Exceed MAX_WHITELIST_MINT'
    );
    require(
      msg.value >= (WHITELIST_SALE_PRICE * _quantity),
      'Primordials :: Insufficient funds'
    );
    require(
      whitelistVerify(_merkleProof),
      'Primordials :: You are not in whitelist'
    );

    totalWhitelistMint[msg.sender] += _quantity;
    _safeMint(msg.sender, _quantity);
    emit SupplyUpdate(totalSupply());
  }

  function allowlistMint(uint256 _quantity)
    external
    payable
    callerIsUser
    mintQCheck(_quantity)
  {
    require(
      saleState == SaleState.ALLOWLIST,
      'Primordials :: ALLOWLIST is closed'
    );
    require(
      (totalAllowlistMint[msg.sender] + _quantity) <= MAX_ALLOWLIST_MINT,
      'Primordials :: Exceed MAX_ALLOWLIST_MINT'
    );
    require(
      msg.value >= (ALLOWLIST_SALE_PRICE * _quantity),
      'Primordials :: Insufficient funds'
    );
    require(
      allowedContractHoldingVerify(msg.sender),
      'Primordials :: You are not in allowlist'
    );

    totalAllowlistMint[msg.sender] += _quantity;
    _safeMint(msg.sender, _quantity);
    emit SupplyUpdate(totalSupply());
  }

  function mint(uint256 _quantity)
    external
    payable
    callerIsUser
    mintQCheck(_quantity)
  {
    require(saleState == SaleState.PUBLIC, 'Primordials :: PUBLIC is closed');
    require(
      msg.value >= (PUBLIC_SALE_PRICE * _quantity),
      'Primordials :: Insufficient funds'
    );

    totalPublicMint[msg.sender] += _quantity;
    _safeMint(msg.sender, _quantity);
    emit SupplyUpdate(totalSupply());
  }

  // MerkleRoot setter
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setSaleState(uint256 _state) external onlyOwner {
    require(_state <= uint256(SaleState.PUBLIC), 'Primordials :: Bad state');
    saleState = SaleState(_state);
  }

  // MerkleRoot Getter
  function getMerkleRoot() external view returns (bytes32) {
    return merkleRoot;
  }

  function setBaseTokenUri(string memory _value) public onlyOwner {
    baseTokenUri = _value;
  }

  function getBaseTokenUri() public view returns (string memory) {
    return baseTokenUri;
  }

  function setPlaceholderTokenUri(string memory _value) public onlyOwner {
    placeholderTokenUri = _value;
  }

  function getPlaceholderTokenUri() public view returns (string memory) {
    return placeholderTokenUri;
  }

  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function revealed() public view returns (bool) {
    return bool(getCurrentTime() > getRevealTime());
  }

  function getRevealTime() public view returns (uint256) {
    return revealTime;
  }

  function setRevealTime(uint256 _revealTime) public onlyOwner {
    revealTime = _revealTime;
  }

  function withdraw() external payable onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success, 'Primordials :: Failed to withdraw');
  }

  /// Request random number through Chainlink VRF
  /// @param _keyHash Chainlink-provided Key Hash
  /// @param _requestConfirmations Variable number of confirmations
  /// @param _callbackGasLimit Callback function gas limit
  function requestRandomWords(
    bytes32 _keyHash,
    uint16 _requestConfirmations,
    uint32 _callbackGasLimit
  ) external onlyOwner {
    require(!link_requestPending, 'Primordials :: VRF request pending');
    require(totalSupply() > 0, 'Primordials :: No tokens minted');
    if (batches.length > 0) {
      require(
        totalSupply() > _getLastBatchClose(),
        'Primordials :: No new tokens to create a batch'
      );
    }
    link_requestPending = true;
    LINK_COORDINATOR.requestRandomWords(
      _keyHash,
      link_subscriptionId,
      _requestConfirmations,
      _callbackGasLimit,
      1
    );
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    // keeping track for seed of each batch.
    link_requestPending = false;
    batches.push(Batch(requestId, randomWords[0], totalSupply()));
  }

  function resetBatches() public onlyOwner {
    delete batches;
  }

  /// Gets the last tokenId of the last batch to be revealed
  function _getLastBatchClose() private view returns (uint256) {
    return batches.length > 0 ? batches[batches.length - 1].until : 0;
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
      'ERC721Metadata: URI query for nonexistent token'
    );

    if (
      !revealed() || tokenId > _getLastBatchClose() || (batches.length == 0)
    ) {
      return placeholderTokenUri;
    }

    return _getMetadata(tokenId);
  }

  function _getMetadata(uint256 tokenId) private view returns (string memory) {
    uint256 batchLowestToken;
    uint256 batchSize;
    uint256 metadataForTokenId;

    Batch memory tokenBatch;

    for (uint256 i = 0; i < batches.length; i++) {
      Batch memory batch = batches[i];

      if (tokenId > batch.until) {
        continue;
      }

      tokenBatch = batches[i];
      batchLowestToken = i > 0 ? batches[i - 1].until + 1 : 1;
      batchSize = batch.until - batchLowestToken + 1;
    }
    uint256[] memory batchMetadata = new uint256[](batchSize);

    // Initializes the metadata array with the base values
    for (uint256 i = batchLowestToken; i <= tokenBatch.until; i++) {
      batchMetadata[i - batchLowestToken] = i;
    }

    // Shuffle batchMetadata array using Fisher–Yates shuffle Algorithm and chainlink VRF random number.
    for (uint256 i = batchLowestToken; i <= tokenBatch.until; i++) {
      uint256 swap = (uint256(keccak256(abi.encode(tokenBatch.seed, i))) %
        (batchSize));
      (batchMetadata[i - batchLowestToken], batchMetadata[swap]) = (
        batchMetadata[swap],
        batchMetadata[i - batchLowestToken]
      );
    }

    metadataForTokenId = batchMetadata[tokenId - batchLowestToken];

    return
      bytes(baseTokenUri).length > 0
        ? string(
          abi.encodePacked(
            baseTokenUri,
            metadataForTokenId.toString(),
            baseExtension
          )
        )
        : '';
  }
}
