// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IVAndVMinter.sol";
import "./IRandomizer.sol";
import "./ITraits.sol";
import "./IVillage.sol";
import "./IGOLD.sol";
import "./VAndV.sol";

contract VAndVMinter is IVAndVMinter, Ownable, Pausable, ReentrancyGuard {
  using Address for address;
  using Strings for uint256;
  using ECDSA for bytes32;

  // Events
  event TokenStolen(address from, address by, uint256 tokenId);

  // mint price
  uint256 public constant MINT_PRICE = 0.069 ether;
  // max mint amount per transaction
  uint8 public constant MINT_PER_TRANSACTION = 2;

  // whether the public sale is active
  bool public saleActive = false;
  // whether the whitelist sale is active
  bool public whitelistActive = false;

  // track which tokens are unrevealed and their chunks
  mapping(uint256 => uint256) private unrevealedTokens;
  // track used nonces
  mapping(bytes => bool) private usedNonces;

  // reference to randomizer
  IRandomizer private randomizer;
  // reference to $GOLD for burning on mint
  IGOLD private gold;
  // reference to traits
  ITraits private traits;
  // reference to vandv
  VAndV private vandv;
  // reference to village
  IVillage private village;

  /**
   * create the contract and auto-pause
   */
  constructor() {
    _pause();
  }

  /**
   * check if the sending user can mint
   * @return if they can mint or not
   */
  function canMint() external view returns (bool) {
    return !paused() && saleActive && vandv.getMinted() < vandv.getMaxTokens();
  }

  /**
   * check to see if a token is ready to be revealed
   * @return if the token can be revealed
   */
  function canReveal(uint256 tokenId) external view returns (bool) {
    return unrevealedTokens[tokenId] > 0 && randomizer.getChunkId() > unrevealedTokens[tokenId];
  }

  /**
   * mint tokens
   * the first 20% cost ETH to claim, the rest cost $GOLD
   * 10% will become vikings, the rest are villagers
   * @param amount the number of tokens to mint
   */
  function mint(uint256 amount) external payable nonReentrant whenNotPaused {
    require(tx.origin == _msgSender() && !_msgSender().isContract(), "V&V: Only EOA");
    require(saleActive, "V&V: Sale not active");
    require(vandv.getMinted() + amount <= vandv.getMaxTokens(), "V&V: All tokens minted");
    require(amount > 0 && amount <= MINT_PER_TRANSACTION, "V&V: Invalid mint amount");

    if (vandv.getMinted() < vandv.getPaidTokens()) {
      require(vandv.getMinted() + amount <= vandv.getPaidTokens(), "V&V: All paid tokens already sold");
      require(msg.value == amount * MINT_PRICE, "V&V: Invalid payment amount");
    } else {
      require(msg.value == 0, "V&V: Invalid payment amount");
    }

    _performMint(amount);
  }

  /**
   * mint tokens via whitelist
   * requires a verifiable signature generated on our servers after the user
   * verifies their wallet address with us
   * @param amount the number of tokens to mint
   * @param nonce the nonce for the transaction
   * @param signature the generated signature from our servers
   */
  function mintWhitelist(uint256 amount, bytes memory nonce, bytes memory signature) external payable nonReentrant whenNotPaused {
    require(tx.origin == _msgSender() && !_msgSender().isContract(), "V&V: Only EOA");
    require(whitelistActive, "V&V: Whitelist not active");
    require(vandv.getMinted() + amount <= vandv.getMaxTokens(), "V&V: All tokens minted");
    require(amount > 0 && amount <= MINT_PER_TRANSACTION, "V&V: Invalid mint amount");
    require(vandv.getMinted() + amount <= vandv.getPaidTokens(), "V&V: All paid tokens already sold");
    require(amount * MINT_PRICE == msg.value, "V&V: Invalid payment amount");
    require(_isValidRequest(nonce, signature), "V&V: Invalid request signature");

    _performMint(amount);
  }

  /**
   * mint tokens for project owner
   * only allowed to mint 50 tokens max
   * @param amount the number of tokens to mint
   */
  function mintReserve(uint256 amount) external payable onlyOwner nonReentrant whenNotPaused {
    require(vandv.getMinted() < 50, "V&V: Can only mint the first 50 tokens maximum");
    require(amount > 0, "V&V: Invalid mint amount");
    require(msg.value == 0, "V&V: Reserve mint is free");

    _performMint(amount);
  }

  /**
   * reveal a token, assigning it traits and rolling to see if it should get
   * stolen by a viking
   * you may have to wait up to an hour to run this function
   * @param tokenIds the token IDs
   */
  function reveal(uint256[] memory tokenIds) external nonReentrant whenNotPaused {
    require(tx.origin == _msgSender() && !_msgSender().isContract(), "V&V: Only EOA");

    for (uint i = 0; i < tokenIds.length; i++) {
      require(vandv.ownerOf(tokenIds[i]) == _msgSender(), "V&V: Doesn't own that token");
      require(unrevealedTokens[tokenIds[i]] > 0, "V&V: Token has already been revealed");

      uint256 chunkId = unrevealedTokens[tokenIds[i]];
      uint256 seed = randomizer.randomChunk(chunkId, tokenIds[i]);

      traits.generateTokenTraits(tokenIds[i], seed);

      delete unrevealedTokens[tokenIds[i]];

      address stolenBy = _rollTokenSteal(tokenIds[i], seed);

      if (stolenBy != address(0x0)) {
        vandv.transferFrom(_msgSender(), stolenBy, tokenIds[i]);

        emit TokenStolen(_msgSender(), stolenBy, tokenIds[i]);
      }
    }
  }

  /**
   * set the address of our randomizer contract
   * @param _randomizer the address
   */
  function setRandomizer(address _randomizer) external onlyOwner {
    randomizer = IRandomizer(_randomizer);
  }

  /**
   * set the address of the gold contract
   * @param _gold the address
   */
  function setGold(address _gold) external onlyOwner {
    gold = IGOLD(_gold);
  }

  /**
   * set the address of the traits contract
   * @param _traits the address
   */
  function setTraits(address _traits) external onlyOwner {
    traits = ITraits(_traits);
  }

  /**
   * set the address of our vandv contract
   * @param _vandv the address
   */
  function setVAndV(address _vandv) external onlyOwner {
    vandv = VAndV(_vandv);
  }

  /**
   * set the address of the village contract
   * @param _village the address
   */
  function setVillage(address _village) external onlyOwner {
    village = IVillage(_village);
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }

  /**
   * enables owner to pause/unpause minting
   * @param enabled if we should pause or unpause
   */
  function setPaused(bool enabled) external onlyOwner {
    if (enabled) {
      _pause();
    } else {
      _unpause();
    }
  }

  /**
   * enables owner to enable and disable the public sale
   * @param enabled if we should enable or disable public sale
   */
  function setSaleActive(bool enabled) external onlyOwner {
    saleActive = enabled;
  }

  /**
   * enables owner to enable and disable the whitelist sale
   * @param enabled if we should enable or disable whitelist sale
   */
  function setWhitelistActive(bool enabled) external onlyOwner {
    whitelistActive = enabled;
  }

  /**
   * mint tokens, called from either the mint or mintWhitelist functions
   * @param amount the number of tokens to mint
   */
  function _performMint(uint256 amount) internal {
    uint256 totalGoldCost = 0;

    for (uint256 i = 0; i < amount; i++) {
      totalGoldCost += _mintGoldCost(vandv.getMinted() + i + 1);
    }

    if (totalGoldCost > 0) {
      gold.burn(_msgSender(), totalGoldCost);
    }

    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = vandv.mint(_msgSender());

      // Track the chunk that the token was minted in +1 so that the reveal of this
      // chunk's seed can't be sandwiched. This means for the reveal we have to wait
      // for 2 seed values to get pushed to the randomizer
      unrevealedTokens[tokenId] = randomizer.getChunkId() + 1;
    }
  }

  /**
   * the first 20% are paid in ETH, so 0 $GOLD
   * the next 20% are 20000 $GOLD
   * the next 20% are 30000 $GOLD
   * the next 20% are 40000 $GOLD
   * the final 20% are 60000 $GOLD
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function _mintGoldCost(uint256 tokenId) internal view returns (uint256) {
    if (tokenId <= vandv.getPaidTokens()) return 0;
    if (tokenId <= vandv.getMaxTokens() * 2 / 5) return 20000 ether;
    if (tokenId <= vandv.getMaxTokens() * 3 / 5) return 30000 ether;
    if (tokenId <= vandv.getMaxTokens() * 4 / 5) return 40000 ether;

    return 60000 ether;
  }

  /**
   * paid tokens will always go to the minter
   * tokens bought using $GOLD have a 10% chance to be given to a random staked viking
   * @param tokenId the token ID
   * @return the owner of the viking, or blackhole if not stolen
   */
  function _rollTokenSteal(uint256 tokenId, uint256 seed) internal view returns (address) {
    if (tokenId <= vandv.getPaidTokens() || ((seed >> 245) % 10) != 0) {
      return address(0x0);
    }

    return village.randomVikingOwner(seed);
  }

  /**
   * check if the signature and nonce is valid using ecdsa
   * @param nonce the nonce encoded inside the signature
   * @param signature the generated signature from our website
   * @return if the signature is valid and matches the nonce + sender
   */
  function _isValidRequest(bytes memory nonce, bytes memory signature) internal returns (bool) {
    if (usedNonces[nonce]) {
      return false;
    }

    usedNonces[nonce] = true;

    bytes32 result = keccak256(abi.encodePacked(_msgSender(), nonce));

    return owner() == result.recover(signature);
  }

}
