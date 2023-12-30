pragma solidity 0.6.7;

library LTokenManager {

  function decimalPriceToRate(string calldata _priceString)
    external
    pure
    returns (uint256[2] memory rate_)
  {
    bool hasDp;
    uint256 dp;
    uint256 result;
    uint256 oldResult;
    bytes memory priceBytes = bytes(_priceString);

    require(priceBytes.length != 0, "Empty string");

    if (priceBytes[0] == "0" && priceBytes.length > 1)
      require(priceBytes[1] == ".", "Bad format: leading zeros");

    for (uint i = 0; i < priceBytes.length; i++) {
      if (priceBytes[i] == "." && !hasDp) {
        require(i < priceBytes.length - 1, "Bad format: expected mantissa");
        hasDp = true;
      } else if (uint8(priceBytes[i]) >= 48 && uint8(priceBytes[i]) <= 57) {
        if (hasDp) dp++;
        oldResult = result;
        result = result * 10 + (uint8(priceBytes[i]) - 48);
        if (oldResult > result || 10**dp < 10**(dp -1))
          revert("Overflow");
      }
      else
        revert("Bad character");
    }

    require(result != 0, "Zero value");

    while (result % 10 == 0) {
      result = result / 10;
      dp--;
    }

    rate_ = [result, 10**dp];
  }
}