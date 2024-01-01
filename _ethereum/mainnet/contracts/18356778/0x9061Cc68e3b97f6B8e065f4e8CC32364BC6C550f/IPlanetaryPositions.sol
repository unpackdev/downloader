// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPlanetaryPositions {

  enum CelestialBody {
    SUN,
    MERCURY,
    VENUS,
    EARTH,
    MOON,
    MARS,
    JUPITER,
    SATURN,
    URANUS,
    NEPTUNE,
    OTHER
  }

    /**
   * @notice The orbital elements consist of 6 quantities which completely define a circular, elliptic, 
   *         parabolic or hyperbolic orbit.
   *
   *         Three of these quantities describe the shape and size of the orbit, and the position of 
   *         the planet in the orbit:
   *         - a : Mean distance, or semi-major axis
   *         - e : Exxcentricity
   *         - T : Time at perihelion
   *         The three remaining orbital elements define the orientation of the orbit in space:
   *         - i : Inclination, i.e. the "tilt" of the orbit relative to the ecliptic.  The inclination 
   *           varies from 0 to 180 degrees. If the inclination is larger than 90 degrees, the planet 
   *           is in a retrogade orbit, i.e. it moves "backwards". The most well-known celestial body 
   *           with retrogade motion is Comet Halley.
   *         - N : (usually written as "Capital Omega") Longitude of Ascending Node. This is the angle, 
   *           along the ecliptic, from the Vernal Point to the Ascending Node, which is the intersection 
   *           between the orbit and the ecliptic, where the planet moves from south of to north of the 
   *           ecliptic, i.e. from negative to positive latitudes.
   *         - w : (usually written as "small Omega") The angle from the Ascending node to the Perihelion, 
   *           along the orbit.
   *
   *         These are the primary orbital elements. From these many secondary orbital elements can be 
   *         computed. Only one is stored in the struct:
   *         - M : Mean Anomaly = n * (t - T)  =  (t - T) * 360_deg / P. Mean Anomaly is 0 at 
   *           perihelion and 180 degrees at aphelion.
   *
   * All values are scaled by 1e18.
   */
  struct OrbitalElements {
    // The celestial body of these orbital elements
    // If filled with some known planets, perturbation corrections will be done
    CelestialBody body;
    // The origin(center) of the orbit
    CelestialBody origin;

    // The "day number" moment in time of these orbital elements, scaled by 1e18
    int dayNumber;

    // Long asc. node, radians
    int N;
    // Inclination; radians
    int i;
    // Arg. of perigee, radians
    int w;
    // Mean distance
    int a;
    // Eccentricity
    int e;
    // Mean anomaly, radians
    int M;
  }

  /**
   * @notice The orbital elements parameters, necessary to compute the orbital elements at a given point
   *         in time.
   */
  struct OrbitalElementsParameters {
    // The celestial body of these orbital elements
    // If filled with some known planets, perturbation corrections will be done
    CelestialBody body;
    // The origin(center) of the orbit
    CelestialBody origin;

    // Long asc. node, radians
    int N;
    int dN;
    // Inclination; radians
    int i;
    int di;
    // Arg. of perigee, radians
    int w;
    int dw;
    // Mean distance
    int a;
    int da;
    // Eccentricity
    int e;
    int de;
    // Mean anomaly, radians
    int M;
    int dM;
  }

  // An axial tilt of a planet
  struct AxialTilt {
    // Radians
    int at;
    int dat;
  }

  
  /**
   * Functions: See doc on PlanetaryPositionLib.sol
   */

  function getDayNumberFromGregorianCalendar(uint year, uint month, uint day, uint hour, uint min) external pure returns (int);

  function getDayNumberFromGregorianCalendar1900to2100(uint year, uint month, uint day, uint hour, uint min) external pure returns (int);

  function getDayNumberFromTimestamp(uint timestamp) external pure returns (int);




  function getBodyAzimuthAltitude(int observerLongitude, int observerLatitude, CelestialBody body, int dayNumber) external pure returns (int azimuth, int altitude, uint distance);

  function getBodyAzimuthAltitudeInRadians(int observerLongitude, int observerLatitude, CelestialBody body, int dayNumber) external pure returns (int azimuth, int altitude, uint distance);

  function getBodyBodyAzimuthAltitudeInRadians(OrbitalElements memory orbitalElements, AxialTilt memory originAxialTilt, OrbitalElements memory newOriginOrbitalElements, int observerLongitude, int observerLatitude, int localSiderealTime) external pure returns (int azimuth, int altitude, uint distance);




  function getBodyTopocentricRADecl(int observerLongitude, int observerLatitude, CelestialBody body, int dayNumber) external pure returns (int rightAscension, int declination, uint distance);

  function getBodyTopocentricRADeclInRadians(int observerLongitude, int observerLatitude, CelestialBody body, int dayNumber) external pure returns (int rightAscension, int declination, uint distance);

  function getBodyBodyTopocentricRADeclInRadians(OrbitalElements memory orbitalElements, AxialTilt memory originAxialTilt, OrbitalElements memory newOriginOrbitalElements, int observerLongitude, int observerLatitude)  external pure returns (int rightAscension, int declination, uint distance);




  function getBodyGeocentricRADecl(CelestialBody body, int dayNumber) external pure returns (int rightAscension, int declination, uint distance);

  function getBodyGeocentricRADeclInRadians(CelestialBody body, int dayNumber) external pure returns (int rightAscension, int declination, uint distance);

  function getBodyBodycentricRADeclInRadians(OrbitalElements memory orbitalElements, AxialTilt memory originAxialTilt, OrbitalElements memory newOriginOrbitalElements) external pure returns (int rightAscension, int declination, uint distance);




  function getBodyEclipticLonLat(CelestialBody body, int dayNumber) external pure returns (int longitude, int latitude, uint distance);

  function getBodyEclipticLonLatInRadians(CelestialBody body, int dayNumber) external pure returns (int longitude, int latitude, uint distance);

  function getBodyEclipticLonLatInRadians(OrbitalElements memory orbitalElements) external pure returns (int longitude, int latitude, uint distance);




  function getLocalSiderealTime(int longitude, int dayNumber) external pure returns (int siderealTime);

  function getLocalSiderealTimeInRadians(int longitude, int dayNumber) external pure returns (int siderealTime);




  function getOrbitalElements(CelestialBody body, int dayNumber) external pure returns (OrbitalElements memory elements);

  function getOrbitalElements(OrbitalElementsParameters memory elementsParameters, int dayNumber) external pure returns (OrbitalElements memory elements);

  function getOrbitalElementsParameters(CelestialBody body) external pure returns (OrbitalElementsParameters memory elementsParameters);
}