// SPDX-License-Identifier: MIT

/**
 * No Branding Clause:
 * The Artwork shall never be used, or authorized for use, as a logo or brand.
 * The Artwork shall never be displayed on “branded” material, in any medium now know or hereafter devised,
 * including without limitation any merchandise, products, or printed or electronic material, that features
 * a trademark, service mark, trade name, tagline, logo, or other indicia identifying a person or entity except
 * for Kristen Visbal or State Street Global Advisors or its affiliates.
 * Purchase for a financial institution:  Your Fearless Girl NFT Image or sculpture may not be used on behalf of
 * any financial institution for commercial or corporate purpose.  A maximum of 20 of the miniatures may be purchased
 * to be used as award for a financial.
 * Purchase for political parties, politicians, activists, or activist groups:  Your Fearless Girl NFT or sculpture may
 * not be used to promote a politician, political party, activist group or used for political purpose.
 */
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./MerkleProof.sol";

import "./AssemblyMath.sol";
import "./ERC721Enumerable.sol";

/// @title Stargazer
contract Stargazer is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // URIs
  string public baseURI =
    'ipfs://QmZWKbE2oxvLV8eS2skCdMRKxXh2y9JoFthW2ZArdpixrt/';

  // Mint costs
  uint256 public publicCost = 0.2 ether;
  uint256 public allowlistCost = 0.16 ether;

  // Sale State
  bool public mintIsActive = true;

  // Allowlist Root
  bytes32 public allowlistMerkleRoot =
    0x6ef44377e05a71a0e02a1b72ae3b41b668ed2498e059ceb91d2505465c1192a6;

  // Treasury wallet
  address public treasury = 0x889F91b971fc6eFB0d0f1a0a3F8C77e718bbdCcd;

  // Supply limits
  uint256 public constant SUPPLY_STRICT_UPPER_BOUND = 5251;
  uint256 public STOCK_STRICT_UPPER_BOUND = 701;

  /**********************************************************************************************/
  /***************************************** EVENTS *********************************************/
  /**********************************************************************************************/
  /**
   * @param allowlist Whether or not cost was associated to the allowlist.
   * @param cost The mew cost of the mint.
   */
  event CostUpdated(bool allowlist, uint256 cost);

  /**
   * @param beneficiary The beneficiary of the tokens.
   * @param tokenId The token identifier.
   */
  event Minted(address indexed beneficiary, uint256 indexed tokenId);

  // Constructor
  constructor() ERC721('Fearless Girl: Stargazer Collection', 'STRGZR') {}

  /*************************************************************************/
  /****************************** MODIFIERS ********************************/
  /*************************************************************************/
  /**
   * @param msgValue Total amount of ether provided by caller.
   * @param numberOfTokens Number of tokens to be minted.
   * @param unitCost Cost per single token.
   * @dev Reverts if incorrect amount provided.
   */
  modifier correctCost(
    uint256 msgValue,
    uint256 numberOfTokens,
    uint256 unitCost
  ) {
    require(
      numberOfTokens * unitCost == msgValue,
      'Stargazer: Incorrect ether amount provided.'
    );
    _;
  }

  /**
   * @param tokenId Token identifier.
   * @dev Reverts if invalid token ID.
   */
  modifier meetsExistence(uint256 tokenId) {
    require(_exists(tokenId), 'Stargazer: Nonexistent token.');
    _;
  }

  /**
   * @dev Reverts if mint is not active.
   */
  modifier mintActive() {
    require(mintIsActive, 'Stargazer: Mint is not active.');
    _;
  }

  /**
   *  @param couponCode Coupon code.
   *  @param proof Merkle proof.
   *  @dev Reverts if coupon code is invalid.
   */
  modifier validCouponCode(string memory couponCode, bytes32[] calldata proof) {
    require(
      MerkleProof.verify(
        proof,
        allowlistMerkleRoot,
        keccak256(abi.encodePacked(couponCode))
      ),
      'Stargazer: Invalid coupon code.'
    );
    _;
  }

  modifier validStockAmount(uint256 amount) {
    require(
      amount + totalSupply() <= SUPPLY_STRICT_UPPER_BOUND,
      'Stargazer: Stock would exceed supply bound.'
    );
    _;
  }

  /**
   * @param count Number of tokens to be minted.
   * @dev Reverts if insufficient supply.
   */
  modifier meetsSupplyConditions(uint256 count) {
    // Ensure meets total supply restrictions.
    require(
      count + totalSupply() < SUPPLY_STRICT_UPPER_BOUND,
      'Stargazer: Supply limit reached.'
    );

    // Ensure meets card type supply restrictions.
    require(
      count < STOCK_STRICT_UPPER_BOUND,
      'Stargazer: Stock limit reached.'
    );
    _;
  }

  /*************************************************************************/
  /****************************** QUERIES **********************************/
  /*************************************************************************/
  /**
   * @param tokenId Token identifier.
   * @return tokenURI uri of the given token ID
   */
  function tokenURI(uint256 tokenId)
    external
    view
    override
    meetsExistence(tokenId)
    returns (string memory)
  {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  /**
   * @param tokenOwner Wallet address
   * @return tokenIds list of tokens owned by the given address.
   */
  function walletOfOwner(address tokenOwner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(tokenOwner);
    if (tokenCount == 0) return new uint256[](0);

    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(tokenOwner, i);
    }
    return tokenIds;
  }

  /**
   * @param account Address checking ownership for.
   * @param tokenIds IDs of tokens we are checking ownership over.
   * @return isOwnerOf regarding whether or not address owns all listed tokens.
   */
  function isOwnerOf(address account, uint256[] calldata tokenIds)
    external
    view
    returns (bool)
  {
    for (uint256 i; i < tokenIds.length; ++i) {
      if (tokenOwners[tokenIds[i]] != account) return false;
    }

    return true;
  }

  /*************************************************************************/
  /*************************** STATE CHANGERS ******************************/
  /*************************************************************************/
  /**
   * @notice Activates/deactivates the public mint.
   * @dev Can only be called by contract owner.
   */
  function flipMintState() external onlyOwner {
    mintIsActive = !mintIsActive;
  }

  /**
   * @param cost New collection cost for allowlist
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setAllowlistCost(uint256 cost) external onlyOwner {
    allowlistCost = cost;
    emit CostUpdated(true, cost);
  }

  /**
   * @param newAllowlistMerkleRoot The new merkle root of the allowlist.
   * @notice Sets the new root of the merkle tree for the allowlist.
   * @dev Only contract owner can call this function.
   */
  function setAllowlistMerkleRoot(bytes32 newAllowlistMerkleRoot)
    external
    onlyOwner
  {
    allowlistMerkleRoot = newAllowlistMerkleRoot;
  }

  /**
   * @param newUri new base uri.
   * @notice Sets the value of the base URI.
   * @dev Only contract owner can call this function.
   */
  function setBaseURI(string memory newUri) external onlyOwner {
    baseURI = newUri;
  }

  /**
   * @param cost New collection cost for public mint
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setPublicCost(uint256 cost) external onlyOwner {
    publicCost = cost;
    emit CostUpdated(false, cost);
  }

  /**
   * @param newStock New stock of the card.
   * @notice Sets the new stock of the card.
   * @dev Only contract owner can call this function.
   */
  function setStock(uint256 newStock)
    external
    onlyOwner
    validStockAmount(newStock)
  {
    STOCK_STRICT_UPPER_BOUND = newStock;
  }

  /**
   * @param newTreasury new treasury address.
   * @notice Sets the address of the treasury.
   * @dev Only contract owner can call this function.
   */
  function setTreasuryWallet(address newTreasury) external onlyOwner {
    require(newTreasury != address(0), 'Stargazer: Invalid treasury address.');
    treasury = newTreasury;
  }

  /*************************************************************************/
  /****************************** MINTING **********************************/
  /*************************************************************************/
  /**
   * @param to Address to mint to.
   * @param tokenId ID of token to be minted.
   * @dev Internal function for minting.
   */
  function _mint(address to, uint256 tokenId) internal virtual override {
    tokenOwners.push(to);

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @param count Number of tokens of the option to mint.
   * @param couponCode Coupon code.
   * @param proof Merkle proof of allowlisted status.
   * @notice Mint function for allowlist addresses for option one.
   */
  function allowlistMint(
    uint256 count,
    string memory couponCode,
    bytes32[] calldata proof
  )
    external
    payable
    mintActive
    validCouponCode(couponCode, proof)
    correctCost(msg.value, count, allowlistCost)
    meetsSupplyConditions(count)
  {
    internalMint(_msgSender(), count);

    // Update stock.
    STOCK_STRICT_UPPER_BOUND -= count;
  }

  /**
   * @param to Address to mint to.
   * @param count Number of tokens of the option to mint.
   */
  function internalMint(address to, uint256 count) internal {
    uint256 numTokens = totalSupply();

    for (uint256 i = 0; i < count; i++) {
      _mint(to, numTokens + i);

      emit Minted(to, numTokens + i);
    }

    delete numTokens;
  }

  /**
   * @param count Number of tokens to mint.
   * @notice Mints the given number of tokens.
   * @dev Sale must be active.
   * @dev Cannot mint more than total supply limit.
   * @dev Cannot mint more than current stock for given card type.
   * @dev Cannot mint more than hard supply cap for given card type.
   * @dev Correct cost amount must be supplied.
   */
  function publicMint(uint256 count)
    external
    payable
    mintActive
    correctCost(msg.value, count, publicCost)
    meetsSupplyConditions(count)
  {
    internalMint(_msgSender(), count);

    // Update stock.
    STOCK_STRICT_UPPER_BOUND -= count;
  }

  /*************************************************************************/
  /****************************** ADMIN **********************************/
  /*************************************************************************/
  /**
   * @notice Withdraw function for contract ethereum.
   * @dev Can only be called by contract owner.
   */
  function withdraw() external onlyOwner {
    payable(treasury).transfer(address(this).balance);
  }

  /**
   * @param amt Array of amounts to mint.
   * @param to Associated array of addresses to mint to.
   * @notice Admin minting function.
   * @dev Cannot mint more than total supply limit.
   * @dev Cannot mint more than current stock for given card type.
   * @dev Cannot mint more than hard supply cap for given card type.
   * @dev Correct cost amount must be supplied.
   * @dev Same lengths for amount and to arrays must be given.
   * @dev Can only be called by contract owner.
   */
  function reserve(uint256[] calldata amt, address[] calldata to)
    external
    onlyOwner
  {
    require(
      amt.length == to.length,
      'Stargazer: Amount array length does not match recipient array or option length.'
    );

    uint256 s = totalSupply();
    uint256 t = AssemblyMath.arraySumAssembly(amt);

    // Can't mint more than total supply limit.
    require(
      t + s < SUPPLY_STRICT_UPPER_BOUND,
      'Stargazer: Cannot mint more than supply limit.'
    );

    // Can't mint more than current stock limit.
    require(
      t < STOCK_STRICT_UPPER_BOUND,
      'Stargazer: Cannot mint more than current stock limit.'
    );

    for (uint256 i = 0; i < to.length; ++i) {
      internalMint(to[i], amt[i]);
    }
    delete s;

    // Update stock.
    STOCK_STRICT_UPPER_BOUND -= t;

    delete t;
  }

  /*************************************************************************/
  /************************ BATCH TRANSFERS ********************************/
  /*************************************************************************/
  /**
   * @param fromAddress Address transferring from.
   * @param toAddress Address transferring to.
   * @param tokenIds IDs of tokens to be transferred.
   * @param data_ Call data argument.
   * @notice Safe variant of batch token transfer function
   */
  function batchSafeTransferFrom(
    address fromAddress,
    address toAddress,
    uint256[] memory tokenIds,
    bytes memory data_
  ) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      safeTransferFrom(fromAddress, toAddress, tokenIds[i], data_);
    }
  }

  /**
   * @param fromAddress Address transferring from.
   * @param toAddress Address transferring to.
   * @param tokenIds IDs of tokens to be transferred.
   * @notice Batch token transfer function
   */
  function batchTransferFrom(
    address fromAddress,
    address toAddress,
    uint256[] memory tokenIds
  ) external {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      transferFrom(fromAddress, toAddress, tokenIds[i]);
    }
  }
}
