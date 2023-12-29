// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC721A.sol";

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./ERC1155Upgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";

import "./DefaultOperatorFiltererUpgradeable.sol";

import "./ISLERC1155MintableUpgradeable.sol";

/**
 * @title Terry's Editions V2
 * @notice Terry's Editions contract. Mint passes (id = 0) can be redeemed by
 * burning a certain amount of KOOKS ERC721 tokens.
 * Other tokens can be minted by holding mint passes.
 */
contract TerrysEditionsV2 is
  DefaultOperatorFiltererUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC1155Upgradeable,
  ERC1155SupplyUpgradeable,
  ERC1155BurnableUpgradeable,
  ISLERC1155MintableUpgradeable
{
  uint256 constant MASK_128 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  address public immutable KOOKS_CONTRACT;

  /**
   * @notice Sets the immutables variables
   * @dev Safe although contract is upgradeable, must be consistent through
   * upgrades
   * @param kooks The address of the KOOKS ERC721 contract
   * pass
   */
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(address kooks) {
    KOOKS_CONTRACT = kooks;
    _disableInitializers();
  }

  /**
   * @notice Initializes the contract
   * @param uri_ The metadata URI of this ERC1155 contract
   */
  function initialize(
    string memory uri_,
    uint256 priceInKOOKS_
  ) public initializer {
    __DefaultOperatorFilterer_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __ERC1155_init(uri_);
    __ERC1155Supply_init();
    __ERC1155Burnable_init();
    redeemOpen = false;
    priceInKOOKS = priceInKOOKS_;
  }

  /**
   * @notice Updates the metadata URI for this ERC1155 contract.
   * Caller must be owner.
   * @param uri_ The new metadata URI to store.
   */
  function setURI(string memory uri_) external onlyOwner {
    _setURI(uri_);
  }

  /* -------------------------------- AIRDROP ------------------------------- */

  /**
   * @notice Airdrops `amount` mint passes with id `id` to `account`,
   * without burning any KOOKS ERC721 tokens. Not affected by pause.
   * Caller must be owner.
   * @param id The token ID to airdrop
   * @param amount The amount of mint passes to airdrop
   * @param account The account to airdrop the mint passes to
   */
  function airdrop(
    address account,
    uint256 id,
    uint256 amount
  ) external onlyOwner {
    _mint(account, id, amount, "");
  }

  /**
   * @notice Batch airdrops `amounts` with ids `ids` to `accounts`,
   * without burning any KOOKS ERC721 tokens. Not affected by pause.
   * Caller must be owner.
   * @param accounts The accounts to airdrop the tokens to
   * @param ids The token IDs to airdrop
   * @param amounts The amounts of mint passes to airdrop
   */
  function airdropBatch(
    address[] memory accounts,
    uint256[] memory ids,
    uint256[] memory amounts
  ) external onlyOwner {
    require(
      accounts.length > 0 &&
        accounts.length == ids.length &&
        accounts.length == amounts.length,
      "inputs do not match"
    );
    for (uint256 i = 0; i < accounts.length; i++) {
      _mint(accounts[i], ids[i], amounts[i], "");
    }
  }

  /* -------------------------------- REDEEM -------------------------------- */

  /**
   * @notice True if redeeming is open
   */
  bool public redeemOpen;
  /**
   * @notice Amount of KOOKS to send to the 0x0000...dEaD address in exchange
   * for one mint pass
   */
  uint256 public priceInKOOKS;

  /**
   * @notice Opens/closes the redeem process. Does not affect airdrops.
   * @param open True to open, false to close. Caller must be owner.
   */
  function setRedeemState(bool open) external onlyOwner {
    redeemOpen = open;
  }

  /**
   * @notice Mints `amount` mint passes in exchange for the right amount of
   * KOOKS ERC721 tokens. This contract must be an approved operator for the
   * KOOKS tokens to exchange.
   * @dev KOOKS is not burnable, so this method transfers the 'burnt' KOOKS to
   * the 0x0000...dEaD address instead
   * @param amount The amount of mint passes to redeem
   * @param kooksIds The IDs of the KOOKS ERC721 tokens to exchange
   */
  function redeem(
    uint256 amount,
    uint256[] calldata kooksIds
  ) external nonReentrant {
    require(redeemOpen, "redeem: closed");
    require(
      amount * priceInKOOKS == kooksIds.length && amount > 0,
      "redeem: too many/few KOOKS to burn"
    );

    for (uint256 i = 0; i < kooksIds.length; i++) {
      IERC721A(KOOKS_CONTRACT).transferFrom(
        _msgSender(),
        DEAD_ADDRESS,
        kooksIds[i]
      );
    }

    _mint(_msgSender(), 0, amount, "");
  }

  /**
   * @notice Updates the price in KOOKS used during the redeem process.
   * Caller must be owner.
   * @param priceInKOOKS_ The new price in KOOKS.
   */
  function setPriceInKOOKS(uint256 priceInKOOKS_) external onlyOwner {
    priceInKOOKS = priceInKOOKS_;
  }

  /* --------------------------------- MINT --------------------------------- */

  /**
   * @notice Mint configuration
   * @dev Config structure:
   * 0   -> 127: token ID to mint
   * 128 -> 255: amount of mintpasses to hold
   */
  uint256 currentMintConfig;

  /**
   * @dev amount of locked passes per token ID and address
   */
  mapping(uint256 => mapping(address => uint256)) lockedPasses;

  /**
   * @notice Opens a mint window for token `tokenId`, and configures the amount
   * of mint passes necessary to hold to mint a single token. Owner only.
   * No mint window can be already open. Cannot open a mint window for token 0.
   * @param tokenId The ID of the token to mint
   * @param mintpassesToHold The amount of mint passes to hold to mint a single
   * token
   */
  function openMint(
    uint128 tokenId,
    uint128 mintpassesToHold
  ) external onlyOwner {
    require(currentMintConfig == 0, "open: another mint is already open");
    require(tokenId != 0, "open: cannot open mint for mint pass");
    currentMintConfig = tokenId | (uint256(mintpassesToHold) << 128);
  }

  /**
   * @notice Closes the currently opened mint window. Owner only.
   */
  function closeMint() external onlyOwner {
    require(currentMintConfig != 0, "close: no mint is open");
    currentMintConfig = 0;
  }

  /**
   * @notice Helper method to get the current mint configuration.
   * If mint is closed, both return values are 0.
   * @return tokenId The tokenID open for mint
   * @return mintpassesToHold The amount of mintpasses required to mint the token.
   */
  function currentMintConfiguration() external view returns (uint128, uint128) {
    return (
      uint128(currentMintConfig & MASK_128),
      uint128((currentMintConfig >> 128))
    );
  }

  /**
   * @notice Locks `amount` mint passes for account `account`. That lock is
   * effective while the mint of `tokenId` is open.
   * @param tokenId The ID of the token whose mint window is open
   * @param account The account to lock tokens from
   * @param amount The amount of tokens to lock
   */
  function _lockMintPasses(
    uint256 tokenId,
    address account,
    uint256 amount
  ) internal {
    lockedPasses[tokenId][account] += amount;
  }

  /**
   * @notice The amount of mint passes locked during the `tokenId` sale for
   * `account`.
   * @param tokenId The ID of the token to check
   * @param account The account to check
   */
  function _lockedMintPasses(
    uint256 tokenId,
    address account
  ) internal view returns (uint256) {
    return lockedPasses[tokenId][account];
  }

  /**
   * @notice The amount of mint passes currently locked for `account`.
   * @param account The account to check
   */
  function lockedMintPasses(address account) public view returns (uint256) {
    return _lockedMintPasses(currentMintConfig & MASK_128, account);
  }

  /**
   * @notice Mints `amount` token from the open mint. Only requirement is to
   * hold a certain amount of mint passes per token minted. Used mintpasses are
   * locked until the mint ends.
   * @param amount The amount of tokens to mint
   */
  function mint(uint256 amount) external nonReentrant {
    uint256 currentMintConfig_ = currentMintConfig;
    uint256 tokenId = currentMintConfig_ & MASK_128;
    uint256 mintpassesToHold = (currentMintConfig_ >> 128);
    require(tokenId != 0, "mint: closed");
    require(
      balanceOf(_msgSender(), 0) - _lockedMintPasses(tokenId, _msgSender()) >=
        mintpassesToHold * amount,
      "mint: not enough mint passes available"
    );

    _lockMintPasses(tokenId, _msgSender(), mintpassesToHold * amount);
    _mint(_msgSender(), tokenId, amount, "");
  }

  /* --------------------------- EXTERNAL MINTING --------------------------- */

  /**
   * @notice Keeps track of allowed minters
   */
  mapping(address => bool) public allowedMinters;

  modifier onlyExternalMinter() {
    require(allowedMinters[_msgSender()], "caller is not external minter");
    _;
  }

  /**
   * @notice Allows/Disallows `account` to mint using mintTo. Owner only.
   * @param account Account to change the status of
   * @param allow true to allow, false to disallow
   */
  function allowMinter(address account, bool allow) external onlyOwner {
    allowedMinters[account] = allow;
  }

  /**
   * @notice Mints `amount` tokens #`tokenId` to `receiver`. Must be an allowed
   * minter.
   * @param receiver Account receiving the token
   * @param tokenId Id of the token to mint
   * @param amount Amount to mint
   */
  function mintTo(
    address receiver,
    uint256 tokenId,
    uint256 amount
  ) external onlyExternalMinter nonReentrant {
    _mint(receiver, tokenId, amount, "");
  }

  /* --------------------------------- HOOKS -------------------------------- */

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override {
    super._afterTokenTransfer(operator, from, to, ids, amounts, data);

    if (from != address(0)) {
      for (uint256 i = 0; i < ids.length; i++) {
        if (ids[i] == 0 && balanceOf(from, 0) < lockedMintPasses(from)) {
          revert("attempting to transfer locked mint passes");
        }
      }
    }
  }

  /* ----------------- OPENSEA ROYALTIES ENFORCEMENT FILTERS ---------------- */

  function setApprovalForAll(
    address operator,
    bool approved
  )
    public
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  )
    public
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  )
    public
    override(ERC1155Upgradeable, IERC1155Upgradeable)
    onlyAllowedOperator(from)
  {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }
}
