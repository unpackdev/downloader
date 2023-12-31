// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./ISLERC1155MintableUpgradeable.sol";

contract SLERC1155ShopUpgradeableV2 is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  uint256 constant MASK_80 = 0xFFFFFFFFFFFFFFFFFFFF;
  uint256 constant MASK_32 = 0xFFFFFFFF;
  uint256 constant MASK_16 = 0xFFFF;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializes the contract
   */
  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
  }

  /**
   * @dev If set, the sale is public and the calling address won't be checked
   */
  uint8 constant PUBLIC_SALE_FLAG = 0x01;

  /**
   * @notice Sale configurations by token address and token ID
   * @dev Sale config structure:
   * 0   ->  15: flags
   * 16  ->  47: max supply
   * 48  -> 79: max per tx
   * 80  -> 159: price in ETH
   * 160 -> 175: currency index
   *
   * Flags:
   * 0x01: PUBLIC_SALE
   *
   * If config == 0, sale does not exist or is closed
   */
  mapping(address => mapping(uint256 => uint256)) saleConfigs;
  /**
   * @notice Authorized buyers by token address and token ID
   */
  mapping(address => mapping(uint256 => mapping(address => bool))) authorizedSaleBuyers;

  mapping(address => mapping(uint256 => uint256)) amountsSold;

  uint256 prevCurrencyIndex;
  mapping(uint256 => address) public currencies;

  event SaleOpen(
    address indexed token,
    uint256 indexed tokenId,
    uint16 currencyIndex,
    uint80 price,
    uint32 maxSupply,
    uint32 maxPerTx,
    uint16 flags
  );

  event SaleEdited(
    address indexed token,
    uint256 indexed tokenId,
    uint16 currencyIndex,
    uint80 price,
    uint32 maxSupply,
    uint32 maxPerTx,
    uint16 flags
  );

  event SaleClosed(address indexed token, uint256 indexed tokenId);

  event Purchase(
    address indexed token,
    uint256 indexed tokenId,
    address recipient,
    uint256 amount
  );

  /**
   * @dev Sets the configuration for a sale. Internal.
   * @param token Address of the token to sell.
   * @param tokenId ID of the token to sell.
   * @param currencyIndex Index of the registered currency to use.
   * @param price  Unit price for this sale.
   * @param maxSupply Max supply of this sale.
   * @param maxPerTx Max amount per tx for this sale. '0' for no limit.
   * @param flags Flags for this sale.
   */
  function _setSale(
    address token,
    uint256 tokenId,
    uint16 currencyIndex,
    uint80 price,
    uint32 maxSupply,
    uint32 maxPerTx,
    uint16 flags
  ) internal {
    saleConfigs[token][tokenId] =
      (uint256(flags) << 240) |
      (uint256(maxSupply) << 208) |
      (uint256(maxPerTx) << 176) |
      (uint256(price) << 96) |
      (uint256(currencyIndex) << 80);
  }

  /**
   * @notice Opens a sale. Sale must not exist already. Owner only.
   * @param token Address of the token to sell. MUST be:
   *   - ERC1155SupplyUpgradeable
   *   - ISLERC1155MintableUpgradeable
   * @param tokenId ID of the token to sell.
   * @param currencyIndex Index of the registered currency to use.
   * @param price  Unit price for this sale.
   * @param maxSupply Max supply of this sale.
   * @param maxPerTx Max amount per tx for this sale. '0' for no limit.
   * @param flags Flags for this sale.
   * @param authorizedBuyers List of authorized buyers. Only used when
   *   PUBLIC_SALE flag is not set.
   */
  function openSale(
    address token,
    uint256 tokenId,
    uint16 currencyIndex,
    uint80 price,
    uint32 maxSupply,
    uint32 maxPerTx,
    uint16 flags,
    address[] calldata authorizedBuyers
  ) external onlyOwner {
    require(saleConfigs[token][tokenId] == 0, "sale already exists");
    require(token != address(0), "token to sell can't be 0x0");
    require(maxSupply > 0, "maxSupply cannot be zero");

    _setSale(token, tokenId, currencyIndex, price, maxSupply, maxPerTx, flags);

    // Set authorized buyers
    for (uint i = 0; i < authorizedBuyers.length; i++) {
      authorizedSaleBuyers[token][tokenId][authorizedBuyers[i]] = true;
    }

    emit SaleOpen(
      token,
      tokenId,
      currencyIndex,
      price,
      maxSupply,
      maxPerTx,
      flags
    );
  }

  /**
   * @notice Edits a sale. Sale musts be open. Owner only.
   * @param token Address of the token of the sale to edit.
   * @param tokenId ID of the token of the sale to edit.
   * @param currencyIndex Index of the registered currency to use.
   * @param price  Unit price for this sale.
   * @param maxSupply Max supply of this sale.
   * @param maxPerTx Max amount per tx for this sale. '0' for no limit.
   * @param flags Flags for this sale.
   * @param buyersToAdd List of new authorized buyers. Only used when
   *   PUBLIC_SALE flag is not set.
   * @param buyersToRemove List of former authorized buyers to remove.
   *   Only used when PUBLIC_SALE flag is not set.
   */
  function editSale(
    address token,
    uint256 tokenId,
    uint16 currencyIndex,
    uint80 price,
    uint32 maxSupply,
    uint32 maxPerTx,
    uint16 flags,
    address[] calldata buyersToAdd,
    address[] calldata buyersToRemove
  ) external onlyOwner {
    require(saleConfigs[token][tokenId] != 0, "sale does not exist");
    require(maxSupply > 0, "maxSupply cannot be zero");
    require(
      maxSupply >= amountsSold[token][tokenId],
      "maxSupply cannot be below the amount of already sold tokens"
    );

    _setSale(token, tokenId, currencyIndex, price, maxSupply, maxPerTx, flags);

    // Add new buyers
    for (uint i = 0; i < buyersToAdd.length; i++) {
      authorizedSaleBuyers[token][tokenId][buyersToAdd[i]] = true;
    }
    // Remove buyers
    for (uint i = 0; i < buyersToRemove.length; i++) {
      authorizedSaleBuyers[token][tokenId][buyersToRemove[i]] = false;
    }

    emit SaleEdited(
      token,
      tokenId,
      currencyIndex,
      price,
      maxSupply,
      maxPerTx,
      flags
    );
  }

  /**
   * @notice Closes a sale. Sale must be open. Owner only.
   * @param token Address of the token to close the sale for.
   * @param tokenId ID of the token to close the sale for.
   */
  function closeSale(address token, uint256 tokenId) external onlyOwner {
    require(saleConfigs[token][tokenId] != 0, "no sale is open for this token");

    saleConfigs[token][tokenId] = 0;

    emit SaleClosed(token, tokenId);
  }

  /**
   * @notice Purchase `amount` tokens with ID `tokenId` from contract `token`.
   *   Caller must be allowed or sale must be public.
   * @param token Token to purchase
   * @param tokenId Tokdn ID to purchase
   * @param amount Amount to purchase
   */
  function purchase(
    address token,
    uint256 tokenId,
    uint256 amount
  ) external payable {
    purchaseFor(token, tokenId, _msgSender(), amount);
  }

  /**
   * @notice Purchase `amount` tokens with ID `tokenId` from contract `token`,
   *   and transfers it to `recipient`.
   *   Caller must be allowed or sale must be public.
   * @param token Token to purchase
   * @param tokenId Tokdn ID to purchase
   * @param recipient Recipient of the tokens
   * @param amount Amount to purchase
   */
  function purchaseFor(
    address token,
    uint256 tokenId,
    address recipient,
    uint256 amount
  ) public payable nonReentrant {
    uint256 saleConfig_ = saleConfigs[token][tokenId];
    require(saleConfig_ != 0, "sale does not exist");

    uint256 flags = saleConfig_ >> 240;
    if (flags & PUBLIC_SALE_FLAG == 0) {
      require(
        authorizedSaleBuyers[token][tokenId][_msgSender()],
        "caller is not an authorized buyer"
      );
    }

    uint256 maxSupply = (saleConfig_ >> 208) & MASK_32;
    require(
      amount + amountsSold[token][tokenId] <= maxSupply,
      "amount would go above max supply for this sale"
    );

    uint256 maxPerTx = (saleConfig_ >> 176) & MASK_32;
    require(maxPerTx == 0 || amount <= maxPerTx, "amount is above max per tx");

    uint256 price = (saleConfig_ >> 96) & MASK_80;
    uint256 currencyIndex = (saleConfig_ >> 80) & MASK_16;
    address currency = currencyIndex == 0
      ? address(0)
      : currencies[currencyIndex];

    if (currency == address(0)) {
      require(msg.value == price * amount, "incorrect value sent");
    } else {
      require(msg.value == 0, "incorrect value sent");
      IERC20Upgradeable(currency).transferFrom(
        msg.sender,
        address(this),
        price * amount
      );
    }

    amountsSold[token][tokenId] += amount;
    ISLERC1155MintableUpgradeable(token).mintTo(recipient, tokenId, amount);

    emit Purchase(token, tokenId, recipient, amount);
  }

  /**
   * @notice Adds an ERC20 currency to be used in sales.
   * @param _newErc20 Currency to accept
   */
  function addErc20Currency(address _newErc20) external onlyOwner {
    prevCurrencyIndex++;
    currencies[prevCurrencyIndex] = _newErc20;
  }

  /**
   * @notice Withdraw all ETH in this contract by transferring it to the caller.
   * Caller must be owner.
   */
  function withdraw() external onlyOwner {
    (bool success, ) = _msgSender().call{value: address(this).balance}("");
    require(success, "withdrawal failed");
  }

  /**
   * @notice Withdraw the balance of this contract for the required ERC20
   * by transferring it to the caller. Caller must be owner.
   * @param _erc20 The ERC20 to withdraw
   */
  function withdrawERC20(address _erc20) external onlyOwner {
    IERC20Upgradeable(_erc20).transfer(
      _msgSender(),
      IERC20Upgradeable(_erc20).balanceOf(address(this))
    );
  }

  /**
   * @notice Returns data for the requested sale. Reverts if sale does not exist
   * @param token The token of the sale
   * @param tokenId The token ID of the sale
   * @return flags The flags of the sale
   * @return maxSupply The max supply of the sale
   * @return maxPerTx The max amount per tx for the sale
   * @return currency The address of the currency used. 0x0 for ETH.
   * @return priceInETH The unit price of a token
   * @return amountSold The amount of tokens sold by this contract
   */
  function getSale(
    address token,
    uint256 tokenId
  )
    external
    view
    returns (
      uint256 flags,
      uint256 maxSupply,
      uint256 maxPerTx,
      address currency,
      uint256 priceInETH,
      uint256 amountSold
    )
  {
    uint256 config = saleConfigs[token][tokenId];
    require(config != 0, "sale does not exist/is closed");
    flags = config >> 240;
    maxSupply = (config >> 208) & MASK_32;
    maxPerTx = (config >> 176) & MASK_32;
    priceInETH = (config >> 96) & MASK_80;
    currency = currencies[(config >> 80) & MASK_16];
    amountSold = amountsSold[token][tokenId];
  }

  /**
   * Returns the amount of tokens sold by this contract, even after a sale is
   * closed.
   * @param token Token address
   * @param tokenId Token ID
   */
  function getAmountSold(
    address token,
    uint256 tokenId
  ) external view returns (uint256) {
    return amountsSold[token][tokenId];
  }

  /**
   * True if `account` is an authorizedBuyer.
   * @param token Token address
   * @param tokenId Token ID
   * @param account Account to check
   */
  function isAuthorized(
    address token,
    uint256 tokenId,
    address account
  ) external view returns (bool) {
    return authorizedSaleBuyers[token][tokenId][account];
  }
}
