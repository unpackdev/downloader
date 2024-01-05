// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./IPriceUSD.sol";

/**
 * @title SWMPriceOracle
 * Serves to get the currently valid (not necessarily current) price of SWM in USD.
 *
 * Note: 0.019 will be returned as (19, 1000). Solidity at this point cannot natively
 *       handle decimal numbers, so we work with two values. Caller needs to be aware of this.
 *
 * @dev Needs to conform to the IPriceUSD interface, otherwise can be rewritten to
 *      use whichever method of setting the price is desired (manual, external oracle...)
 */
contract SWMPriceOracle is IPriceUSD, Ownable {
  event UpdatedSWMPriceUSD(
    uint256 oldPriceNumerator,
    uint256 oldPriceDenominator,
    uint256 newPriceNumerator,
    uint256 newPriceDenominator
  );

  uint256 public priceNumerator;
  uint256 public priceDenominator;

  constructor(uint256 _priceNumerator, uint256 _priceDenominator) {
    require(_priceNumerator > 0, 'numerator must not be zero');
    require(_priceDenominator > 0, 'denominator must not be zero');

    priceNumerator = _priceNumerator;
    priceDenominator = _priceDenominator;

    emit UpdatedSWMPriceUSD(0, 0, _priceNumerator, _priceNumerator);
  }

  /**
   *  This function gets the price of SWM in USD
   *
   *  0.0736 is returned as (736, 10000)
   *  @return numerator The numerator of the currently valid price of SWM in USD
   *  @return denominator The denominator of the currently valid price of SWM in USD
   **/
  function getPrice() external override view returns (uint256 numerator, uint256 denominator) {
    return (priceNumerator, priceDenominator);
  }

  /**
   *  This function can be called manually or programmatically to update the
   *  currently valid price of SWM in USD
   *
   *  To update to 0.00378 call with (378, 100000)
   *  @param _priceNumerator The new SWM price in USD
   *  @param _priceDenominator The new SWM price in USD
   *  @return true on success
   */
  function updatePrice(uint256 _priceNumerator, uint256 _priceDenominator)
    external
    onlyOwner
    returns (bool)
  {
    require(_priceNumerator > 0, 'numerator must not be zero');
    require(_priceDenominator > 0, 'denominator must not be zero');

    emit UpdatedSWMPriceUSD(priceNumerator, priceDenominator, _priceNumerator, _priceDenominator);

    priceNumerator = _priceNumerator;
    priceDenominator = _priceDenominator;

    return true;
  }
}
