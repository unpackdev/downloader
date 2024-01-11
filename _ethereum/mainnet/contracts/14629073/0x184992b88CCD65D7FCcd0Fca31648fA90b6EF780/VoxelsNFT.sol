// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Initializable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./AddressUpgradeable.sol";
import "./OpenSeaGasFreeListing.sol";

interface IWireToken is IERC20 {
  function mint(address, uint256) external;
  function burn(address, uint256) external;
}

interface IRandomGenerator {
  function getRandom(uint, uint) external view returns (uint256);
}

/**
 * VoxelsNFT
 * 1 ~ 1414: Voxel Group 1
 * 1415 ~ 2828: Voxel Group 2
 * 2829 ~ 4242: Voxel Group 3
 * 4243 ~ 5656: Voxel Group Genesis (Burn for mint)
 */
contract VoxelsNFT is
  Initializable,
  ERC721EnumerableUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using AddressUpgradeable for address payable;

  IWireToken public wireToken;
  IRandomGenerator public randomGenerator;
  address payable public paymentSplitter;

  // Mapping from an address to manage and control states
  mapping(address => bool) public admins;
  mapping(address => uint256) public userData;
  mapping(uint256 => bytes32) public merkles;

  // Max supply of NFTs
  uint256 public MAX_NFT_SUPPLY;

  // Total supply of voxels
  uint public MAX_VOXELS_SUPPLY;

  // Pending count
  uint256 public pendingCount; // Initial voxels

  // Pending Ids
  uint256[5657] private _pendingIds;

  /**
    0 - paused
    1 - presale 
    2 - presale reserve
    3 - public reserve
    4 - public
   */
  uint256 public activeSale;

  // Wires
  mapping(uint => uint) public wires;

  // Stages
  mapping(uint => uint) public stages;

  // Stage burn amounts of $WIRE
  mapping(uint => uint) public stageBurnAmounts;

  // Minted
  bool[5667] public minted;

  uint public mintPrice;
  uint256 public mintPerTx;
  bool public genesisMintLive;
  bool public singleBurnAllowed;
  bool public stageAdvanceAllowed;

  string public _baseTokenURI;
  uint public singleBurnAmount;

  // Token amount for genesis
  uint public burnTokenAmount;

  uint private _genesisTokenId;

  // === EVENTS ===
  event GenesisMint(
    uint indexed tokenId,
    uint indexed wires,
    uint[] tokenIds
  );
  event VoxelBurned(address indexed owner, uint indexed tokenId);
  event VoxelMint(address indexed owner, uint indexed tokenId);
  event StageAdvance(uint indexed tokenId, uint indexed stageLevel);

  modifier onlyAdmin() {
    require(admins[msg.sender], "Only Admin can execute");
    _;
  }

  function initialize(
    address _wireToken,
    address _randomGenerator,
    address _paymentSplitter
  ) external initializer {
    __ERC721_init("VoxelsNFT", "VNFT");
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();

    paymentSplitter = payable(_paymentSplitter);

    wireToken = IWireToken(_wireToken);
    randomGenerator = IRandomGenerator(_randomGenerator);

    MAX_NFT_SUPPLY = 5656;
    MAX_VOXELS_SUPPLY = 4242;
    pendingCount = 4242;
    mintPrice = 0.1 ether;
    singleBurnAllowed = false;
    stageAdvanceAllowed = false;
    burnTokenAmount = 30 ether;
    singleBurnAmount = 10 ether;
    _genesisTokenId = 4243;
    mintPerTx = 1;
    _baseTokenURI = "https://voxels-api.herokuapp.com/voxels/";
    
    // presale
    merkles[1] = 0xfc90e0350a0c0232a3d9f27d633d1f48cef893ea9a714f4f5cdf99b6e75d3119;
    // presale reserve 
    merkles[2] = 0x033f96e91713c63bb92616bbccad78ad46a997a2489ccf32c0a72e1a034787e5;
    // public reserve
    merkles[3] = 0x50e8167e7351e8bbd169c9782d184b871b5020bdaf224b5b423e3ccda6928dac;

    admins[msg.sender] = true;
  }

  function adminAmountMint(uint amount, address recipient)
    external
    onlyAdmin
    nonReentrant
  {
    require(recipient != address(0), "Invalid recipient");
    _randomMint(recipient, amount, amount);
  }

  function adminSelectionMint(uint[] memory tokenIds, address recipient)
    external
    onlyAdmin
    nonReentrant
  {
    require(recipient != address(0), "Invalid recipient");
    for (uint i = 0; i < tokenIds.length; i++) {
      require(
        tokenIds[i] >= 1 && tokenIds[i] <= MAX_VOXELS_SUPPLY,
        "Invalid token id"
      );
      require(!minted[tokenIds[i]], "Already minted");
      uint nftIndex = _getPendingIndexById(tokenIds[i], 1, MAX_VOXELS_SUPPLY);
      _popPendingAtIndex(nftIndex);
      minted[tokenIds[i]] = true;
      _mint(recipient, tokenIds[i]);
      _setWires(tokenIds[i]);
      emit VoxelMint(recipient, tokenIds[i]);
    }
  }

  modifier mintConditions(uint256 amount, uint256 saleValue) {
    require(amount > 0, "Cannot be zero");
    require(msg.value >= amount * mintPrice, "Incorrect ETH price");
    require(activeSale == saleValue, "Not Live");
    _;
  }

  modifier checkMerkle(uint256 maxCount, address sender, uint256 saleValue, bytes32[] memory proof) {
    require(verify(merkles[saleValue], proof, sender, maxCount), "Not in list");
    _;
  }

  /**
    @dev presaleMint has an allocation of 3000
    OG/Voxel Legends - 3
    Regular Wired - 2

    Creating different entry points to make maintain easier
   */
  function presaleMint(uint256 amount, uint256 max, bytes32[] memory proof) 
    external
    payable
    mintConditions(amount, 1)
    checkMerkle(max, msg.sender, 1, proof)
    nonReentrant
  {
    require(userData[msg.sender] + amount <= max, "Exceeds supply");
    userData[msg.sender] += amount;
    _randomMint(msg.sender, amount, max);
  }
  
  /**
    @dev presaleMintReserve has an allocation of 900 (3900)
    OG/Voxel Legends - 3
    Regular Wired - 2
    Valued - 1

    Creating different entry points to make maintain easier
   */
  function presaleReserveMint(uint256 amount, uint256 max, bytes32[] memory proof)
    external
    payable
    mintConditions(amount, 2)
    checkMerkle(max, msg.sender, 2, proof)
    nonReentrant
  {
    require(userData[msg.sender] + amount <= max, "Exceeds supply");
    userData[msg.sender] += amount;
    _randomMint(msg.sender, amount, max);
  }
  
  /**
    @dev publicReserveMint has an allocation of 242 (4142)
    OG/Voxel Legends - 3
    Regular Wired - 2
    Valued - 1
    Unvalued - 1

    Creating different entry points to make maintain easier
   */
  function publicReserveMint(uint256 amount, uint256 max, bytes32[] memory proof) 
    external
    payable
    mintConditions(amount, 3)
    checkMerkle(max, msg.sender, 3, proof)
    nonReentrant
  {
    require(userData[msg.sender] + amount <= max, "Exceeds supply");
    userData[msg.sender] += amount;
    _randomMint(msg.sender, amount, max);
  }

  /**
    @dev public - remaining
   */
  function mint(uint256 amount)
    external
    payable
    mintConditions(amount, 4)
    nonReentrant
  {
    _randomMint(msg.sender, amount, mintPerTx);
  }

  function _randomMint(
    address to,
    uint amount,
    uint limit
  ) internal {
    require(amount <= limit, "randomMint: Surpasses maxItemsPerTx");
    require(
      totalSupply() + amount <= MAX_VOXELS_SUPPLY,
      "randomMint: Sold out"
    );

    for (uint i = 0; i < amount; i++) {
      uint randomNum = randomGenerator.getRandom(pendingCount, totalSupply());
      uint16 index = uint16((randomNum % pendingCount) + 1);
      uint256 tokenId = _popPendingAtIndex(index);
      minted[tokenId] = true;
      _mint(to, tokenId);
      _setWires(tokenId);
      emit VoxelMint(to, tokenId);
    }
  }

  function _setWires(uint tokenId) internal {
    uint voxelType = (tokenId - 1) / 1414;
    if (tokenId <= 1 + voxelType * 1414 + 621) {
      // Wire 1 - 14.67%
      wires[tokenId] = 1;
    } else if (tokenId <= 1 + voxelType * 1414 + 1031) {
      // Wire 2 - 9.67%
      wires[tokenId] = 2;
    } else if (tokenId <= 1 + voxelType * 1414 + 1286) {
      // Wire 3 - 6%
      wires[tokenId] = 3;
    } else {
      // Wire 4 - 3%
      wires[tokenId] = 4;
    }
  }

  function genesisMint(uint256[] calldata tokenIds)
    external
    whenNotPaused
  {
    require(genesisMintLive, "Not Live");
    require(
      wireToken.balanceOf(msg.sender) >= burnTokenAmount,
      "genesisMint: Must have necessary $WIRE tokens"
    );
    require(tokenIds.length == 3, "genesisMint: Must burn 3 voxels");

    uint genesisWires = 0;
    uint i;

    // Verify found 3 different voxels
    uint256 multiplerCheck;
    for (i = 0; i < tokenIds.length; i++) {
      multiplerCheck |= 1 << (2**((tokenIds[i] - 1) / 1414));
    }
    require(
      multiplerCheck == 22,
      "genesisMint: Must burn 3 different voxels from each group"
    );

    // Calculate wires of a genesis voxel and burn 3 voxels
    for (i = 0; i < 3; i++) {
      require(tokenIds[i] <= MAX_VOXELS_SUPPLY, "Cannot burn genesis");
      require(ownerOf(tokenIds[i]) == msg.sender, "Not owner");
      genesisWires += wires[tokenIds[i]];
      _burn(tokenIds[i]);
      emit VoxelBurned(msg.sender, tokenIds[i]);
    }
    // Burn necessary $WIRE tokens
    wireToken.burn(msg.sender, burnTokenAmount);

    // Mint a genesis voxel
    minted[_genesisTokenId] = true;
    wires[_genesisTokenId] = genesisWires;
    _mint(msg.sender, _genesisTokenId);
    emit GenesisMint(_genesisTokenId, genesisWires, tokenIds);
    _genesisTokenId += 1;
  }

  function singleBurn(uint tokenId) external whenNotPaused {
    require(singleBurnAllowed, "singleBurn: Not allowed");
    require(
      tokenId >= 1 && tokenId <= MAX_VOXELS_SUPPLY,
      "singleBurn: Only voxels are allowed"
    );
    require(
      ownerOf(tokenId) == msg.sender,
      "singleBurn: Must be owner of the voxel"
    );

    _burn(tokenId);
    wireToken.transfer(msg.sender, wires[tokenId] * singleBurnAmount);
    emit VoxelBurned(msg.sender, tokenId);
  }

  function stageAdvance(uint[] calldata tokenIds) external whenNotPaused {
    require(stageAdvanceAllowed, "stageAdvance: Not allowed");
    uint requiredBurnAmount = 0;
    uint i;

    for (i = 0; i < tokenIds.length; i++) {
      require(tokenIds[i] > MAX_VOXELS_SUPPLY, "stageAdvance: Must be genesis");
      require(
        ownerOf(tokenIds[i]) == msg.sender,
        "stageAdvance: Must be owner of the genesis"
      );
      requiredBurnAmount += stageBurnAmounts[stages[tokenIds[i]]];
    }
    require(
      wireToken.balanceOf(msg.sender) >= requiredBurnAmount,
      "stageAdvance: Must have necessary $WIRE tokens"
    );

    for (i = 0; i < tokenIds.length; i++) {
      wireToken.burn(msg.sender, stageBurnAmounts[stages[tokenIds[i]]]);
      stages[tokenIds[i]] += 1;
      emit StageAdvance(tokenIds[i], stages[tokenIds[i]]);
    }
  }

  function verify(
    bytes32 root,
    bytes32[] memory proof,
    address account,
    uint256 maxCount
  ) public pure returns (bool) {
    return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(account, maxCount)));
  }

  // === ADMIN FUNCTIONS ===

  function pauseMint() external onlyAdmin {
    _pause();
  }

  function unpauseMint() external onlyAdmin {
    _unpause();
  }

  function setActiveSale(uint256 _activeSale) external onlyAdmin {
    require(_activeSale <= 4);
    activeSale = _activeSale;
  }

  function setSingleBurnAllowed(bool _singleBurnAllowed) external onlyAdmin {
    singleBurnAllowed = _singleBurnAllowed;
  }

  function setSingleBurnAmount(uint _singleBurnAmount) external onlyAdmin {
    singleBurnAmount = _singleBurnAmount;
  }

  function setStageBurnAmount(uint _stageId, uint _burnAmount)
    external
    onlyAdmin
  {
    stageBurnAmounts[_stageId] = _burnAmount;
  }

  function setStageAdvanceAllowed(bool _stageAdvanceAllowed)
    external
    onlyAdmin
  {
    stageAdvanceAllowed = _stageAdvanceAllowed;
  }

  function setMintPrice(uint _mintPrice) external onlyAdmin {
    mintPrice = _mintPrice;
  }

  function setMaxSupply(uint256 _MAX_VOXELS_SUPPLY) external onlyAdmin {
    MAX_VOXELS_SUPPLY = _MAX_VOXELS_SUPPLY;
  }

  function setGenesisMintLive(bool _live) external onlyAdmin {
    genesisMintLive = _live;
  }

  function setBurnTokenAmount(uint _burnTokenAmount) external onlyAdmin {
    burnTokenAmount = _burnTokenAmount;
  }

  function setBaseTokenURI(string memory __baseTokenURI) public onlyAdmin {
    _baseTokenURI = __baseTokenURI;
  }

  // === OWNABLE FUNCTIONS ===
  function addAdmin(address admin_) external onlyOwner {
    admins[admin_] = true;
  }

  function removeAdmin(address admin_) external onlyOwner {
    admins[admin_] = false;
  }

  function setMintPerTx(uint256 _mintPerTx) external onlyAdmin {
    mintPerTx = _mintPerTx;
  }

  function setMerkle(uint256 index, bytes32 root) external onlyAdmin {
    merkles[index] = root;
  }

  function setPaymentSplitter(address _paymentSplitter)
    external
    onlyOwner
  {
    paymentSplitter = payable(_paymentSplitter);
  }

  // === PAYMENT FUNCTIONS ===

  /// @notice Processes an incoming payment on the contract and
  /// sends it to the payment splitter.
  function withdraw() external onlyAdmin nonReentrant {
    paymentSplitter.sendValue(address(this).balance);
  }

  // === METADATA FUNCTIONS ===
  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return
      string(
        abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId))
      );
  }

  /**
    @notice Returns true if either standard isApprovedForAll() returns true or
    the operator is the OpenSea proxy for the owner.
    */
  function isApprovedForAll(address owner_, address operator_)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      super.isApprovedForAll(owner_, operator_) || admins[msg.sender] ||
      OpenSeaGasFreeListing.isApprovedForAll(owner_, operator_);
  }

  function _getPendingAtIndex(uint256 _index) internal view returns (uint256) {
    return _pendingIds[_index] + _index;
  }

  function _getPendingIndexById(
    uint256 tokenId,
    uint256 startIndex,
    uint256 totalCount
  ) internal view returns (uint256) {
    for (uint256 i = 0; i < totalCount; i++) {
      uint256 pendingTokenId = _getPendingAtIndex(i + startIndex);
      if (pendingTokenId == tokenId) {
        return i + startIndex;
      }
    }
    revert("Invalid token id(pending index)");
  }

  function _popPendingAtIndex(uint256 _index) internal returns (uint256) {
    uint256 tokenId = _getPendingAtIndex(_index);
    if (_index != pendingCount) {
      uint256 lastPendingId = _getPendingAtIndex(pendingCount);
      _pendingIds[_index] = lastPendingId - _index;
    }
    pendingCount--;
    return tokenId;
  }
}
