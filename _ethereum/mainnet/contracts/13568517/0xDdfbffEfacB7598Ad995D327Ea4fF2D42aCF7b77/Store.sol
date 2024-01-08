// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./AggregatorV3Interface.sol";
import "./Balance.sol";

contract Store is Ownable, Pausable {
  /// @notice Balance contract address.
  Balance public balance;

  /// @notice Price feed oracle.
  AggregatorV3Interface public priceFeed;

  /// @notice Products.
  mapping(uint8 => uint256) public products;

  event ProductChanged(uint8 indexed product, uint256 priceUSD);

  event PriceFeedChanged(address indexed priceFeed);

  event Buy(uint8 indexed product, address indexed recipient);

  constructor(address _balance, address _priceFeed) {
    balance = Balance(_balance);
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  /**
   * @notice Change price feed oracle address.
   * @param _priceFeed New price feed oracle address.
   */
  function changePriceFeed(address _priceFeed) external onlyOwner {
    priceFeed = AggregatorV3Interface(_priceFeed);
    emit PriceFeedChanged(_priceFeed);
  }

  /**
   * @notice Update product price.
   * @param id Product identificator.
   * @param priceUSD Product price in USD with price feed oracle decimals (zero if product is not for sale).
   */
  function changeProduct(uint8 id, uint256 priceUSD) external onlyOwner {
    products[id] = priceUSD;
    emit ProductChanged(id, priceUSD);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Get current product price.
   * @param product Target product.
   * @return Product price in ETH.
   */
  function price(uint8 product) public view returns (uint256) {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    require(answer > 0, "Store: invalid price");

    return (products[product] * 1e18) / uint256(answer);
  }

  /**
   * @notice Buy product.
   * @param product Target product.
   * @param recipient Product recipient.
   * @param priceMax Maximum price.
   * @param deadline Timestamp of deadline.
   */
  function buy(
    uint8 product,
    address recipient,
    uint256 priceMax,
    uint256 deadline
  ) external payable whenNotPaused {
    // solhint-disable-next-line not-rely-on-time
    require(deadline >= block.timestamp, "Store: expired");
    uint256 currentPrice = price(product);
    require(currentPrice > 0, "Store: negative or zero price");
    require(currentPrice <= priceMax, "Store: excessive price");

    balance.claim(_msgSender(), 0, currentPrice, "STORE_BUY");
    emit Buy(product, recipient);
  }
}
