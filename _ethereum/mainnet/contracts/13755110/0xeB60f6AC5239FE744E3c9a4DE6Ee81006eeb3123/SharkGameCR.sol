// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ISharkGame.sol";
import "./ICoral.sol";
import "./ITraits.sol";
import "./IChum.sol";
import "./ISharks.sol";
import "./IRandomizer.sol";


contract SharkGameCR is ISharkGame, Ownable, ReentrancyGuard, Pausable {
  using MerkleProof for bytes32[];

  event MintCommitted(address indexed owner, uint256 indexed amount);
  event MintRevealed(address indexed owner, uint256 indexed amount);

  struct MintCommit {
    bool stake;
    uint16 amount;
  }

  uint256 public treasureChestTypeId;
  // max $CHUM cost
  uint256 private maxChumCost = 80000 ether;
  uint256 private ethCost = 0.04 ether;

  // address -> commit # -> commits
  mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;
  // address -> commit num of commit need revealed for account
  mapping(address => uint16) private _pendingCommitId;
  // commit # -> offchain random
  mapping(uint16 => uint256) private _commitRandoms;
  uint16 private _commitId = 1;
  uint16 private pendingMintAmt;
  // 0 - no sale
  // 1 - whitelist
  // 2 - public sale
  uint8 public saleStage = 0;
  // counter of how much has been minted
  mapping(address => uint16) private _mintedByWallet;
  mapping(address => uint16) public freeMints;
  bytes32 whitelistMerkelRoot;

  // address => can call addCommitRandom
  mapping(address => bool) private admins;

  // reference to the Tower for choosing random Dragon thieves
  ICoral public coral;
  // reference to $CHUM for burning on mint
  IChum public chumToken;
  // reference to Traits
  ITraits public traits;
  // reference to NFT collection
  ISharks public sharksNft;

  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(chumToken) != address(0) && address(traits) != address(0)
        && address(sharksNft) != address(0) && address(coral) != address(0)
        , "Contracts not set");
      _;
  }

  function setContracts(address _chum, address _traits, address _sharksNft, address _coral) external onlyOwner {
    chumToken = IChum(_chum);
    traits = ITraits(_traits);
    sharksNft = ISharks(_sharksNft);
    coral = ICoral(_coral);
  }

  function setWhitelistRoot(bytes32 val) public onlyOwner {
    whitelistMerkelRoot = val;
  }

  function addFreeMints(address addr, uint16 qty) public onlyOwner {
    freeMints[addr] += qty;
  }

  function setSaleStage(uint8 val) public onlyOwner {
    saleStage = val;
  }

  /** EXTERNAL */

  function getPendingMint(address addr) external view returns (MintCommit memory) {
    require(_pendingCommitId[addr] != 0, "no pending commits");
    return _mintCommits[addr][_pendingCommitId[addr]];
  }

  function hasMintPending(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0;
  }

  function canMint(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0 && _commitRandoms[_pendingCommitId[addr]] > 0;
  }

  // Seed the current commit id so that pending commits can be revealed
  function addCommitRandom(uint256 seed) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    _commitRandoms[_commitId] = seed;
    _commitId += 1;
  }

  function deleteCommit(address addr) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    uint16 commitIdCur = _pendingCommitId[_msgSender()];
    require(commitIdCur > 0, "No pending commit");
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
  }

  function forceRevealCommit(address addr) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
    reveal(addr);
  }

  /** Initiate the start of a mint. This action burns $CHUM, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint16 amount, bool stake, bytes32[] memory proof) external whenNotPaused nonReentrant payable {
    require(tx.origin == _msgSender(), "Only EOA");
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    require(saleStage > 0, "Sale not started yet");
    uint16 minted = sharksNft.minted();
    uint16 maxTokens = sharksNft.getMaxTokens();
    uint16 paidTokens = sharksNft.getPaidTokens();
    bool isWhitelistOnly = saleStage < 2;
    uint16 maxTxMint = isWhitelistOnly ? 4 : 6;
    uint16 maxWalletMint = isWhitelistOnly ? 4 : 12;
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= maxTxMint, "Invalid mint amount");
    require(minted + pendingMintAmt > paidTokens || _mintedByWallet[_msgSender()] + amount <= maxWalletMint, "Invalid mint amount");
    if (isWhitelistOnly) {
      require(whitelistMerkelRoot != 0, "Whitelist not set");
      require(
        proof.verify(whitelistMerkelRoot, keccak256(abi.encodePacked(_msgSender()))),
        "You aren't whitelisted"
      );
    }

    uint256 totalChumCost = 0;
    uint256 totalEthCost = 0;
    // Loop through the amount of
    for (uint16 i = 1; i <= amount; i++) {
      uint16 tokenId = minted + pendingMintAmt + i;
      if (tokenId <= paidTokens) {
        totalEthCost += ethCost;
      }
      totalChumCost += mintCostChum(tokenId, maxTokens);
    }

    if (freeMints[_msgSender()] >= 0) {
      if (freeMints[_msgSender()] >= amount) {
        totalEthCost = 0;
        freeMints[_msgSender()] -= amount;
      } else {
        totalEthCost -= ethCost * freeMints[_msgSender()];
        freeMints[_msgSender()] = 0;
      }
    }

    require(msg.value >= totalEthCost, "Not enough ETH");
    if (totalChumCost > 0) {
      chumToken.burn(_msgSender(), totalChumCost);
      chumToken.updateOriginAccess();
    }
    uint16 amt = uint16(amount);
    _mintCommits[_msgSender()][_commitId] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = _commitId;
    pendingMintAmt += amt;
    _mintedByWallet[_msgSender()] += amount;
    emit MintCommitted(_msgSender(), amount);
  }

  /** Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
    * the user is pending for has been assigned a random seed. */
  function mintReveal() external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA1");
    reveal(_msgSender());
  }

  function reveal(address addr) internal {
    uint16 commitIdCur = _pendingCommitId[addr];
    require(commitIdCur > 0, "No pending commit");
    require(_commitRandoms[commitIdCur] > 0, "random seed not set");
    uint16 minted = sharksNft.minted();
    MintCommit memory commit = _mintCommits[addr][commitIdCur];
    pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](commit.amount);
    uint256 seed = _commitRandoms[commitIdCur];
    for (uint k = 0; k < commit.amount; k++) {
      minted++;
      // scramble the random so the steal / treasure mechanic are different per mint
      seed = uint256(keccak256(abi.encode(seed, addr)));
      address recipient = selectRecipient(seed);
      tokenIds[k] = minted;
      if (!commit.stake || recipient != addr) {
        sharksNft.mint(recipient, seed);
      } else {
        sharksNft.mint(address(coral), seed);
      }
    }
    sharksNft.updateOriginAccess(tokenIds);
    if(commit.stake) {
      coral.addManyToCoral(addr, tokenIds);
    }
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
    emit MintCommitted(addr, tokenIds.length);
  }

  /**
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCostChum(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
    if (tokenId <= maxTokens / 6) return 0;
    if (tokenId <= maxTokens / 3) return maxChumCost / 4;
    if (tokenId <= maxTokens * 2 / 3) return maxChumCost / 2;
    return maxChumCost;
  }

  /** INTERNAL */

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked dragon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Dragon thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
    address thief = coral.randomTokenOwner(ISharks.SGTokenType.ORCA, seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setMaxChumCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxChumCost = _amount;
  }

  /** Allow the contract owner to set the pending mint amount.
    * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been
    *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
    * This function should not be called lightly, this will have negative consequences on the game. */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
  * enables an address to mint / burn
  * @param addr the address to enable
  */
  function addAdmin(address addr) external onlyOwner {
      admins[addr] = true;
  }

  /**
  * disables an address from minting / burning
  * @param addr the address to disbale
  */
  function removeAdmin(address addr) external onlyOwner {
      admins[addr] = false;
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}
