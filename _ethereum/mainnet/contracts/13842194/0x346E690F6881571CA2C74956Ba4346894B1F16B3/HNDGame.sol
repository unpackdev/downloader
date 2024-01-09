// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IHNDGame.sol";
import "./IKingdom.sol";
import "./ITraits.sol";
import "./Iexp.sol";
import "./IHND.sol";
import "./IShop.sol";



contract HNDGame is IHNDGame, Ownable, ReentrancyGuard, Pausable {

  event MintCommitted(address indexed owner, uint256 indexed amount);
  event MintRevealed(address indexed owner, uint256 indexed amount);

  struct MintCommit {
    bool stake;
    uint16 amount;
  }

  // Maximum price in EXP of the final game mints
  uint256 private maxExpCost = 105000 ether;

  // pricing
  uint256 public presalePrice = 0.07 ether;
  uint256 public publicSalePrice = 0.08 ether;


  // address -> commit # -> commits
  mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;

  // address -> commit num of commit need revealed for account
  mapping(address => uint16) private _pendingCommitId;

  // commit # -> offchain random
  mapping(uint16 => uint256) private _commitRandoms;


  // whitelisted address => number of tokens minted during whitelist.
  // if address did not mint then they will not be in this list.
  mapping(address => uint256) private _whitelistClaims;

  // root of the merkle trie constructed from whitelist claimants
  bytes32 private whitelistMerkleRoot;

  uint16 private _commitBatch = 1;

  uint16 private pendingMintAmt;

  bool public isPublicSale;

  // address => can call addCommitRandom
  mapping(address => bool) private admins;


  // reference to the Kingdom for choosing random Demon thieves
  IKingdom public kingdom;

  ITraits public traits;

  IEXP public expToken;

  IHND public HNDNFT;

  address private kingdomAddr;

  address private treasury;

  // reference to loot
  IShop public shop;

  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(expToken) != address(0) && address(traits) != address(0) 
        && address(expToken) != address(0) && address(kingdom) != address(0) && address(shop) != address(0)
        , "Contracts not set");
      _;
  }

  modifier requireEOA() {
    require(tx.origin == _msgSender(), "Only EOA");

    _;
  }

  function setContracts(address _exp, address _traits, address _HND, address _kingdom, address _shop) external onlyOwner {
    expToken = IEXP(_exp);
    traits = ITraits(_traits);
    HNDNFT = IHND(_HND);
    kingdom = IKingdom(_kingdom);
    kingdomAddr = _kingdom;
    shop = IShop(_shop);
  }


  function setTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function setWhitelistMerkleRoot(bytes32 root) external onlyOwner {
    whitelistMerkleRoot = root;
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
  function addCommitRandom(uint256 seed, bytes32 parentBlockHash) external {
    require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");

    if (parentBlockHash != "") {
      // we poll to get the previous blockhash and continually submit tx until it's included
      // no gas waste as flashbots rpc fails if tx will revert
      require(blockhash(block.number - 1) == parentBlockHash, "block was uncled");
    }
    _commitRandoms[_commitBatch] = seed;
    _commitBatch += 1;
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



  /** Initiate the start of a mint during the whitelisted minting period **/

  function whitelistMintCommit(uint256 index, uint256 a, uint256 amount, bytes32[] calldata merkleProof, bool stake) external payable whenNotPaused nonReentrant requireEOA {
    
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    require(_whitelistClaims[_msgSender()] + amount <= 2, "exceeds whitelist mint limit");
    // all whitelist mints take place during the presale phase, no need to check for other prices.
    require(amount * presalePrice == msg.value, "Invalid payment amount");

    
    // verify merkle proof
    bytes32 node = keccak256(abi.encodePacked(index, _msgSender(), a));
    require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, node), "Not on Whitelist: Invalid Merkle proof.");  
  
    _whitelistClaims[_msgSender()] += amount;

    uint16 amt = uint16(amount);
    _mintCommits[_msgSender()][_commitBatch] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = _commitBatch;
    pendingMintAmt += amt;
    emit MintCommitted(_msgSender(), amount);

  }

  /** Initiate the start of a mint. This action burns $EXP, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external payable whenNotPaused nonReentrant requireEOA {
    require(isPublicSale == true, "Public Sale not started!");
    require(_pendingCommitId[_msgSender()] == 0, "Already have pending mints");
    uint16 minted = HNDNFT.minted();
    uint256 maxTokens = HNDNFT.getMaxTokens();
    uint256 paidTokens = HNDNFT.getPaidTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount <= 10, "HNDGame: Maximum mint amount of 10");

    if (minted < paidTokens) {
      require(minted + amount <= paidTokens, "HNDGame: Paid tokens sold out");
      require(amount * publicSalePrice == msg.value, "HNDGame: Invalid payment amount");
    } else {
      require(msg.value == 0);
      uint256 totalExpCost = 0;
      // Loop through the amount of 
      for (uint i = 1; i <= amount; i++) {
        totalExpCost += mintCost(minted + pendingMintAmt + i, maxTokens);
      }

      if (totalExpCost > 0) {
        // burn 30% (and the recycled 35%)
        expToken.burn(_msgSender(), totalExpCost * 13 / 20);
        
        // recycle the 35%
        kingdom.recycleExp(totalExpCost * 7/20);

        // 35% to treasury
        expToken.transferFrom(_msgSender(), treasury, totalExpCost * 7 / 20);


        expToken.updateOriginAccess();
      }
    }

    uint16 amt = uint16(amount);
    _mintCommits[_msgSender()][_commitBatch] = MintCommit(stake, amt);
    _pendingCommitId[_msgSender()] = _commitBatch;
    pendingMintAmt += amt;
    emit MintCommitted(_msgSender(), amount);
  }

  /** Reveal the commits for this user. This will be when the user gets their NFT, and can only be done when the commit id that
    * the user is pending for has been assigned a random seed. */
  function mintReveal() external whenNotPaused nonReentrant requireEOA {
    reveal(_msgSender());
  }

  function reveal(address addr) internal {
    uint16 commitIdCur = _pendingCommitId[addr];
    require(commitIdCur > 0, "No pending commit");
    require(_commitRandoms[commitIdCur] > 0, "random seed not set");
    uint16 minted = HNDNFT.minted();
    MintCommit memory commit = _mintCommits[addr][commitIdCur];
    pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](commit.amount);
    uint256 seed = _commitRandoms[commitIdCur];
    for (uint k = 0; k < commit.amount; k++) {
      minted++;

      // change seed per mint
      seed = uint256(keccak256(abi.encode(seed, addr)));
      address recipient = selectRecipient(seed);

      tokenIds[k] = minted;
      if (!commit.stake || recipient != addr) {
        HNDNFT.mint(recipient, seed);
      } else {
        HNDNFT.mint(address(kingdom), seed);
      }
    }
    HNDNFT.updateOriginAccess(tokenIds);
    if(commit.stake) {
      kingdom.addManyToKingdom(addr, tokenIds);
    }
    delete _mintCommits[addr][commitIdCur];
    delete _pendingCommitId[addr];
    emit MintCommitted(addr, tokenIds.length);
  }

  /** 
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
    if (tokenId <= maxTokens * 2 / 5) return 20000 ether;
    if (tokenId <= maxTokens * 3 / 5) return 45000 ether;
    if (tokenId <= maxTokens * 4 / 5) return 80000 ether;
    if (tokenId <= maxTokens)         return 105000 ether; 
    return maxExpCost;
  }

  /** INTERNAL */

  /**
   * the first 20% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked demon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Demon thief's owner)
   */
  function selectRecipient(uint256 seed) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
    address thief = kingdom.randomDemonOwner(seed >> 144); // 144 bits reserved for trait selection
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

  function startPublicSale(bool _saleStarted) external onlyOwner {
    isPublicSale = _saleStarted;
  }

  function setMaxExpCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxExpCost = _amount;
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