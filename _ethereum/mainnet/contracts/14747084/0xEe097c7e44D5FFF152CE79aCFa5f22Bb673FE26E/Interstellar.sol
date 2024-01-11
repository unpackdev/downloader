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
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";

import "./AssemblyMath.sol";
import "./ERC721Enumerable.sol";

/// @title Interstellar
contract Interstellar is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // URIs
  string public baseURI =
    'ipfs://Qmcs6by4em9FK6Az9bB5ZebDv38HNEJTJE6dVeitjHU3mh/';

  // Mint Option 1 Costs
  uint256 public optionOneCost = 3.65 ether;
  uint256 public optionOneAllowlistCost = 3.25 ether;

  // Mint Option 2 Costs
  uint256 public optionTwoCost = 1.42 ether;
  uint256 public optionTwoAllowlistCost = 1.14 ether;

  // Sale State
  bool public mintIsActive = true;

  // Allowlist Root
  bytes32 public allowlistMerkleRoot =
    0x6ef44377e05a71a0e02a1b72ae3b41b668ed2498e059ceb91d2505465c1192a6;

  // Treasury wallet
  address public treasury = 0x889F91b971fc6eFB0d0f1a0a3F8C77e718bbdCcd;

  // Supply limits
  uint256 public constant SUPPLY_STRICT_UPPER_BOUND = 226;
  uint256 public optionOneSupplyLeft = 125;
  uint256 public optionTwoSupplyLeft = 100;

  /**********************************************************************************************/
  /***************************************** EVENTS *********************************************/
  /**********************************************************************************************/
  /**
   * @param allowlist Whether or not cost was associated to the allowlist.
   * @param optionOne Whether or not the cost was associated to option one.
   * @param cost The mew cost of the mint.
   */
  event CostUpdated(bool allowlist, bool optionOne, uint256 cost);

  /**
   * @param beneficiary The beneficiary of the tokens.
   * @param tokenId The token identifier.
   * @param optionOne Whether the token is minted for Option One or Option Two.
   */
  event Minted(
    address indexed beneficiary,
    uint256 indexed tokenId,
    bool optionOne
  );

  constructor() ERC721('Fearless Girl: Interstellar Collection', 'INTSTLR') {}

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
      'Interstellar: Incorrect ether amount provided.'
    );
    _;
  }

  /**
   * @param tokenId Token identifier.
   * @dev Reverts if invalid token ID.
   */
  modifier meetsExistence(uint256 tokenId) {
    require(_exists(tokenId), 'Interstellar: Nonexistent token.');
    _;
  }

  /**
   * @dev Reverts if mint is not active.
   */
  modifier mintActive() {
    require(mintIsActive, 'Interstellar: Mint is not active.');
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
      'Interstellar: Invalid coupon code.'
    );
    _;
  }

  /**
   * @param count Number of tokens to be minted.
   * @param optionOne True if option one is to be minted.
   * @dev Reverts if insufficient supply.
   */
  modifier meetsSupplyConditions(uint256 count, bool optionOne) {
    // Ensure meets total supply restrictions.
    require(
      count + totalSupply() < SUPPLY_STRICT_UPPER_BOUND,
      'Interstellar: Supply limit reached.'
    );

    // Ensure there is enough supply of the proposed option left.
    require(
      count <= (optionOne ? optionOneSupplyLeft : optionTwoSupplyLeft),
      'Interstellar: Insufficient option supply.'
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
   * @param cost New collection cost for option one allowlists
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setOptionOneAllowlistCost(uint256 cost) external onlyOwner {
    optionOneAllowlistCost = cost;
    emit CostUpdated(true, true, cost);
  }

  /**
   * @param cost New collection cost for option one
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setOptionOneCost(uint256 cost) external onlyOwner {
    optionOneCost = cost;
    emit CostUpdated(false, true, cost);
  }

  /**
   * @param cost New collection cost for option two allowlists
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setOptionTwoAllowlistCost(uint256 cost) external onlyOwner {
    optionTwoAllowlistCost = cost;
    emit CostUpdated(true, false, cost);
  }

  /**
   * @param cost New collection cost for option two
   * @notice Amount to mint one token
   * @dev Only contract owner can call this function.
   */
  function setOptionTwoCost(uint256 cost) external onlyOwner {
    optionTwoCost = cost;
    emit CostUpdated(false, false, cost);
  }

  /**
   * @param newTreasury new treasury address.
   * @notice Sets the address of the treasury.
   * @dev Only contract owner can call this function.
   */
  function setTreasuryWallet(address newTreasury) external onlyOwner {
    require(
      newTreasury != address(0),
      'Interstellar: Invalid treasury address.'
    );
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
   * @param optionOne Option one or two.
   * @param couponCode Coupon code.
   * @param proof Merkle proof of allowlisted status.
   * @notice Mint function for allowlist addresses for option one.
   */
  function allowlistMint(
    uint256 count,
    bool optionOne,
    string memory couponCode,
    bytes32[] calldata proof
  )
    external
    payable
    mintActive
    validCouponCode(couponCode, proof)
    correctCost(
      msg.value,
      count,
      (optionOne ? optionOneAllowlistCost : optionTwoAllowlistCost)
    )
    meetsSupplyConditions(count, optionOne)
  {
    internalMint(_msgSender(), count, optionOne);

    // Update supply.
    if (optionOne) {
      optionOneSupplyLeft = optionOneSupplyLeft - count;
    } else {
      optionTwoSupplyLeft = optionTwoSupplyLeft - count;
    }
  }

  /**
   * @param to Address to mint to.
   * @param count Number of tokens of the option to mint.
   * @param optionOne Option one or two.
   */
  function internalMint(
    address to,
    uint256 count,
    bool optionOne
  ) internal {
    // Mint options.
    uint256 numTokens = totalSupply();

    for (uint256 i = 0; i < count; i++) {
      _mint(to, numTokens + i);

      emit Minted(to, numTokens + i, optionOne);
    }

    delete numTokens;
  }

  /**
   * @param count Number of tokens to mint.
   * @param optionOne Whether or not to mint option one.
   * @notice Mints the given number of tokens.
   * @dev Sale must be active.
   * @dev Cannot mint more than supply limit.
   * @dev Correct cost amount must be supplied.
   */
  function publicMint(uint256 count, bool optionOne)
    external
    payable
    mintActive
    correctCost(msg.value, count, (optionOne ? optionOneCost : optionTwoCost))
    meetsSupplyConditions(count, optionOne)
  {
    internalMint(_msgSender(), count, optionOne);

    // Update supply.
    if (optionOne) {
      optionOneSupplyLeft = optionOneSupplyLeft - count;
    } else {
      optionTwoSupplyLeft = optionTwoSupplyLeft - count;
    }
  }

  /*************************************************************************/
  /****************************** ADMIN **********************************/
  /*************************************************************************/
  /**
   * @notice Withdraw function for contract ethereum.
   */
  function withdraw() external onlyOwner {
    payable(treasury).transfer(address(this).balance);
  }

  /**
   * @param amt Array of amounts to mint.
   * @param to Associated array of addresses to mint to.
   * @param optionOne Whether or not to mint option one.
   * @notice Admin minting function.
   * @dev Can only be called by contract owner.
   */
  function reserve(
    uint256[] calldata amt,
    address[] calldata to,
    bool optionOne
  ) external onlyOwner {
    require(
      amt.length == to.length,
      'Interstellar: Amount array length does not match recipient array or option length.'
    );

    uint256 s = totalSupply();
    uint256 t = AssemblyMath.arraySumAssembly(amt);

    require(
      s + t < SUPPLY_STRICT_UPPER_BOUND,
      'Interstellar: Cannot mint more than supply limit.'
    );

    // Ensure there is enough supply of the proposed option left.
    require(
      t <= (optionOne ? optionOneSupplyLeft : optionTwoSupplyLeft),
      'Interstellar: Insufficient option supply.'
    );

    for (uint256 i = 0; i < to.length; ++i) {
      internalMint(to[i], amt[i], optionOne);
    }

    // Update supply.
    if (optionOne) {
      optionOneSupplyLeft = optionOneSupplyLeft - t;
    } else {
      optionTwoSupplyLeft = optionTwoSupplyLeft - t;
    }

    delete t;
    delete s;
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
