//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract DSMath {
  uint256 internal constant WAD = 10 ** 18;
  uint256 internal constant RAY = 10 ** 27;

  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x >= y ? x : y;
  }

  function imin(int256 x, int256 y) internal pure returns (int256 z) {
    return x <= y ? x : y;
  }

  function imax(int256 x, int256 y) internal pure returns (int256 z) {
    return x >= y ? x : y;
  }

  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

// Using DSMath from DappHub https://github.com/dapphub/ds-math
// More info on DSMath and fixed point arithmetic in Solidity:
// https://medium.com/dapphub/introducing-ds-math-an-innovative-safe-math-library-d58bc88313da

/**
 * @title Interest
 * @author Nick Ward
 * @dev Uses DSMath's wad and ray math to implement (approximately)
 * continuously compounding interest by calculating discretely compounded
 * interest compounded every second.
 */
contract InterestHelper is DSMath {
  /**
   * @dev Uses an approximation of continuously compounded interest
   * (discretely compounded every second)
   * @param _principal The principal to calculate the interest on.
   *   Accepted in wei.
   * @param _rate The interest rate. Accepted as a ray representing
   *   1 + the effective interest rate per second, compounded every
   *   second. As an example:
   *   I want to accrue interest at a nominal rate (i) of 5.0% per year
   *   compounded continuously. (Effective Annual Rate of 5.127%).
   *   This is approximately equal to 5.0% per year compounded every
   *   second (to 8 decimal places, if max precision is essential,
   *   calculate nominal interest per year compounded every second from
   *   your desired effective annual rate). Effective Rate Per Second =
   *   Nominal Rate Per Second compounded every second = Nominal Rate
   *   Per Year compounded every second * conversion factor from years
   *   to seconds
   *   Effective Rate Per Second = 0.05 / (365 days/yr * 86400 sec/day)
   *                             = 1.5854895991882 * 10 ** -9
   *   The value we want to send this function is
   *   1 * 10 ** 27 + Effective Rate Per Second * 10 ** 27
   *   = 1000000001585489599188229325
   *   This will return 5.1271096334354555 Dai on a 100 Dai principal
   *   over the course of one year (31536000 seconds)
   * @param _age The time period over which to accrue interest. Accepted
   *   in seconds.
   * @return The new principal as a wad. Equal to original principal +
   *   interest accrued
   */
  function accrueInterest(
    uint256 _principal,
    uint256 _rate,
    uint256 _age
  ) public pure returns (uint256) {
    return rmul(_principal, rpow(_rate, _age));
  }

  /**
   * @dev Takes in the desired nominal interest rate per year, compounded
   *   every second (this is approximately equal to nominal interest rate
   *   per year compounded continuously). Returns the ray value expected
   *   by the accrueInterest function
   * @param _rateWad A wad of the desired nominal interest rate per year,
   *   compounded continuously. Converting from ether to wei will effectively
   *   convert from a decimal value to a wad. So 5% rate = 0.05
   *   should be input as yearlyRateToRay( 0.05 ether )
   * @return 1 * 10 ** 27 + Effective Interest Rate Per Second * 10 ** 27
   */
  function yearlyRateToRay(uint256 _rateWad) public pure returns (uint256) {
    return add(wadToRay(1 ether), rdiv(wadToRay(_rateWad), weiToRay(365 * 86400)));
  }

  //// Fixed point scale factors
  // wei -> the base unit
  // wad -> wei * 10 ** 18. 1 ether = 1 wad, so 0.5 ether can be used
  //      to represent a decimal wad of 0.5
  // ray -> wei * 10 ** 27

  // Go from wad (10**18) to ray (10**27)
  function wadToRay(uint256 _wad) internal pure returns (uint256) {
    return mul(_wad, 10 ** 9);
  }

  // Go from wei to ray (10**27)
  function weiToRay(uint256 _wei) internal pure returns (uint256) {
    return mul(_wei, 10 ** 27);
  }
}
