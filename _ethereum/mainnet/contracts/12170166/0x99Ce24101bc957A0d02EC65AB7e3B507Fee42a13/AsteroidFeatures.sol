// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./ABDKMath64x64.sol";
import "./InfluenceSettings.sol";
import "./Procedural.sol";
import "./IPlanets.sol";


/**
 * @dev Contract which generates all standard features of an asteroid including its spectral type and
 * orbital elements.
 */
contract AsteroidFeatures {
  using ABDKMath64x64 for *;
  using Procedural for bytes32;

  IPlanets planets;

  constructor(IPlanets _planets) {
    planets = _planets;
  }

  /**
   * @dev Returns the asteroid's individual seed
   * @param _asteroidId Number from 1 to the total supply of asteroids
   */
  function getAsteroidSeed(uint _asteroidId) public pure returns (bytes32) {
    require(_asteroidId > 0 && _asteroidId <= InfluenceSettings.TOTAL_ASTEROIDS);
    return InfluenceSettings.MASTER_SEED.derive(_asteroidId);
  }

  /**
   * @dev Generates the asteroid radius in meters
   * @param _asteroidId Number from 1 to the total supply of asteroids
   */
  function getRadius(uint _asteroidId) public pure returns (uint64) {
    int128 exponent = int128(-475).fromInt().div(int128(1000).fromInt());
    int128 baseRadius = InfluenceSettings.MAX_RADIUS.fromInt();
    int128 radiusMod = exponent.mul(_asteroidId.fromUInt().ln()).exp();
    int128 radius = baseRadius.mul(radiusMod);
    return radius.toUInt();
  }

  /**
   * @dev Generates the asteroid radius in meters
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getRadiusBySeed(bytes32 _seed) public pure returns (uint64) {
    bytes32 node = _seed.derive("radius");
    int128 base = int128(node.getIntBetween(0, 1000001)); // FIX THIS!
    int128 exponent = int128(-1).fromInt().div(int128(2).fromInt());
    int128 baseRadius = InfluenceSettings.MAX_RADIUS.fromInt();
    int128 radiusMod = exponent.mul(base.fromInt().ln()).exp();
    int128 radius = baseRadius.mul(radiusMod);
    return radius.toUInt();
  }

  /**
   * @dev Utility method to get asteroid spectral type
   * @param _asteroidId Number from 1 to the total supply of asteroids
   */
  function getSpectralType(uint _asteroidId) public pure returns (uint) {
    return getSpectralTypeBySeed(getAsteroidSeed(_asteroidId));
  }

  /** @dev Utility method to get asteroid spectral type
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getSpectralTypeBySeed(bytes32 _seed) public pure returns (uint) {
    uint region = getRegion(_seed);

    if (region == 0) {
      return getMainBeltType(_seed);
    } else {
      return getTrojanType(_seed);
    }
  }

  /**
   * @dev Utility method to get asteroid orbital elements
   * @param _asteroidId Number from 1 to the total supply of asteroids
   */
  function getOrbitalElements(uint _asteroidId) public view returns (uint[6] memory orbitalElements) {
    return getOrbitalElementsBySeed(getAsteroidSeed(_asteroidId));
  }

  /**
   * @dev Utility method to get asteroid orbital elements
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getOrbitalElementsBySeed(bytes32 _seed) public view returns (uint[6] memory orbitalElements) {
    uint region = getRegion(_seed);

    if (region == 0) {
      uint spectralType = getMainBeltType(_seed);
      orbitalElements = getMainBeltElements(_seed, spectralType);
    } else {
      orbitalElements = getTrojanElements(_seed);
    }

    return orbitalElements;
  }

  /**
   * @dev Gets the region (Main belt or Trojan) for the asteroid
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getRegion(bytes32 _seed) internal pure returns (uint) {
    bytes32 node = _seed.derive("region");
    uint roll = uint(node.getIntBetween(0, 101));

    if (roll >= 20) {
      return 0;
    } else {
      return 1;
    }
  }

  /**
   * @dev Generates the spectral type of a main belt asteroid
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getMainBeltType(bytes32 _seed) internal pure returns (uint) {
    uint16[11] memory ratios = [ 6500, 125, 250, 500, 250, 125, 1000, 500, 125, 500, 125 ];

    bytes32 node =_seed.derive("spectral");
    int64 roll = node.getIntBetween(1, 10001);
    uint asteroidCount = 0;

    for (uint i = 0; i < ratios.length; i++) {
      asteroidCount += ratios[i];

      if (uint(roll) <= asteroidCount) {
        return i;
      }
    }

    return uint(ratios.length - 1);
  }

  /**
   * @dev Generates orbital elements for main belt asteroids
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getMainBeltElements(bytes32 _seed, uint _spectralType) internal pure returns (uint[6] memory) {
    bytes32 node;

    // Define min / max semi-major axis for each spectral type and generate for asteroid
    int128[11] memory minAxis = [ int128(800),  1200, 2900, 800,  1200, 2400, 800,  1200, 2400, 1200, 2900 ];
    int128[11] memory maxAxis = [ int128(3100), 2250, 3100, 2600, 2350, 3000, 2400, 2250, 2750, 2300, 3100 ];
    node = _seed.derive("axis");
    uint axis = uint(node.getNormalIntBetween(minAxis[uint(_spectralType)], maxAxis[uint(_spectralType)]));

    // Generate eccentricity between 0 and 0.4
    node = _seed.derive("eccentricity");
    uint ecc = uint(node.getNormalIntBetween(0, 400));

    // Generate inclination between 0 and 35 deg
    node = _seed.derive("inclination");
    uint inc = uint(node.getDecayingIntBelow(4001));

    // Get rotational elements for main belt
    uint[3] memory rotElements = getMainBeltRotationalElements(_seed);

    return [ axis, ecc, inc, rotElements[0], rotElements[1], rotElements[2] ];
  }

  /**
   * @dev Generates the rotational elements for main belt asteroids
   * @param _seed The seed returned from getAsteroidSeed
   */
  function getMainBeltRotationalElements(bytes32 _seed) internal pure returns (uint[3] memory) {
    bytes32 node;

    // Generate ascending node between 0 and 360 deg
    node = _seed.derive("ascending");
    uint lan = uint(node.getIntBetween(0, 36000));

    // Generate argument of periapsis between 0 and 360 deg
    node = _seed.derive("periapsis");
    uint peri = uint(node.getIntBetween(0, 36000));

    // Generate mean anomaly at epoch between 0 and 360 deg
    node = _seed.derive("anomaly");
    uint anom = uint(node.getIntBetween(0, 36000));

    return [ lan, peri, anom ];
  }

  /**
   * @dev Generates the spectral type for Trojan belt asteroids
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getTrojanType(bytes32 _seed) internal pure returns (uint) {
    uint16[11] memory ratios = [ 2750, 0, 1500, 0, 0, 0, 0, 0, 0, 0, 5750 ];

    bytes32 node = _seed.derive("spectral");
    int64 roll = node.getIntBetween(1, 10001);
    uint asteroidCount = 0;

    for (uint i = 0; i < ratios.length; i++) {
      asteroidCount += ratios[i];

      if (uint(roll) <= asteroidCount) {
        return i;
      }
    }

    return uint(ratios.length - 1);
  }

  /**
   * @dev Generates a set of orbital elements for a trojan asteroid based on the parent planet
   * @param _seed The seed returned by getAsteroidSeed
   */
  function getTrojanElements(bytes32 _seed) internal view returns (uint[6] memory) {
    bytes32 node;

    // Get details for the planet we're using as parent
    uint16[6] memory planet = planets.getPlanetWithTrojanAsteroids();

    // Semi-major axis must be identical to result in the same oribtal period
    uint axis = planet[0];

    // Eccentricity can vary by up to 12.5%
    node = _seed.derive("eccentricity");
    uint ecc = uint(node.getNormalIntBetween(0, 125));

    // Inclination can vary up to 35 deg
    node = _seed.derive("inclination");
    uint inc = planet[2] + uint(node.getDecayingIntBelow(4001));

    uint[3] memory rotElements = getTrojanRotationalElements(_seed, planet[3], planet[4], planet[5]);
    return [ axis, ecc, inc, rotElements[0], rotElements[1], rotElements[2] ];
  }

  /**
   * @dev Since we're roughly approximating Trojan orbits (in reality they orbit the Lagrange point as well as
   * the star) we're going to vary orbits related to the parent. This is achieved by varying the sum of
   * the longitude of ascending node, argument of periapsis, and mean anomaly at epoch.
   * @param _seed The seed returned from getAsteroidSeed
   * @param _l Planet's longitude of ascending node
   * @param _p Planet's argument of periapsis
   * @param _a Planet's mean anomaly at epch
   */
  function getTrojanRotationalElements(
    bytes32 _seed,
    uint _l,
    uint _p,
    uint _a
  ) internal pure returns (uint[3] memory) {
    bytes32 node;
    node = _seed.derive("lagrange");
    uint lagrangeShift = 4500 + 22500 * uint(node.getIntBetween(0, 2)) + uint(node.getNormalIntBetween(0, 4501));
    uint planetSum = _l + _p + _a + lagrangeShift;

    // Longitude of ascending node can vary
    node = _seed.derive("ascending");
    uint lan = uint(node.getIntBetween(0, 36000));

    // Argument of periapsis can vary
    node = _seed.derive("periapsis");
    uint peri = uint(node.getIntBetween(0, 36000));

    // Mean anomaly at epoch must get the asteroid in proper alignment with planetSum
    uint anom = (planetSum % 36000) + 36000 - ((lan + peri) % 36000);
    anom = anom % 36000;

    return [ lan, peri, anom ];
  }
}
