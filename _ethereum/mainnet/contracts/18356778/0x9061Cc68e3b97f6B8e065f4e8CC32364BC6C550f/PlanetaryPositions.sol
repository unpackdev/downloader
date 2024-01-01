// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./PlanetaryPositionsLib.sol";
import "./IPlanetaryPositions.sol";

/**
 * @notice This contracts call a library that compute the planetary positions of the moon, the sun, and the 
 *         7 others planet of the solarsystem.
 *         Planetary positions can be computed in ecliptic longitude/latitude, in 
 *         right ascension/declination, both geocentric and topocentric, and in azimuth/altitude.
 *         The algorithms are from Paul Schlyter, who published them at 
 *         https://stjarnhimlen.se/comp/tutorial.html, 
 *         as well as examples at https://stjarnhimlen.se/comp/ppcomp.html.
 *         Some comments from his website were copied into here for better clarity.
 *         All numbers are scaled by 1e18.
 * 
 *         Method comments are in the Library source code.
 */
contract PlanetaryPositions is IPP {
    function getDayNumberFromGregorianCalendar(uint year, uint month, uint day, uint hour, uint min) public pure returns (int) {
        return PPL.getDayNumberFromGregorianCalendar(year, month, day, hour, min);
    }

    function getDayNumberFromGregorianCalendar1900to2100(uint year, uint month, uint day, uint hour, uint min) public pure returns (int) {
        return PPL.getDayNumberFromGregorianCalendar1900to2100(year, month, day, hour, min);
    }

    function getDayNumberFromTimestamp(uint timestamp) public pure returns (int) {
        return PPL.getDayNumberFromTimestamp(timestamp);
    }



    function getBodyAzimuthAltitudeNow(int observerLongitude, int observerLatitude, CelestialBody body) public view returns (int azimuth, int altitude, uint distance) {

        return PPL.getBodyAzimuthAltitude(observerLongitude, observerLatitude, IPP.CelestialBody(uint(body)), getDayNumberFromTimestamp(block.timestamp));
    }

    function getBodyAzimuthAltitude(int observerLongitude, int observerLatitude, CelestialBody body, int dayNumber) public pure returns (int azimuth, int altitude, uint distance) {

        return PPL.getBodyAzimuthAltitude(observerLongitude, observerLatitude, IPP.CelestialBody(uint(body)), dayNumber);
    }

    function getBodyAzimuthAltitudeInRadians(int observerLongitude, int observerLatitude, IPP.CelestialBody body, int dayNumber) public pure returns (int azimuth, int altitude, uint distance) {
        return PPL.getBodyAzimuthAltitudeInRadians(observerLongitude, observerLatitude, body, dayNumber);
    }

    function getBodyBodyAzimuthAltitudeInRadians(IPP.OrbitalElements memory orbitalElements, IPP.AxialTilt memory originAxialTilt, IPP.OrbitalElements memory newOriginOrbitalElements, int observerLongitude, int observerLatitude, int localSiderealTime) public pure returns (int azimuth, int altitude, uint distance) {
        return PPL.getBodyBodyAzimuthAltitudeInRadians(orbitalElements, originAxialTilt, newOriginOrbitalElements, observerLongitude, observerLatitude, localSiderealTime);
    }




    function getBodyTopocentricRADeclNow(int observerLongitude, int observerLatitude, IPP.CelestialBody body) public view returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyTopocentricRADecl(observerLongitude, observerLatitude, body, getDayNumberFromTimestamp(block.timestamp));
    }

    function getBodyTopocentricRADecl(int observerLongitude, int observerLatitude, IPP.CelestialBody body, int dayNumber) public pure returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyTopocentricRADecl(observerLongitude, observerLatitude, body, dayNumber);
    }

    function getBodyTopocentricRADeclInRadians(int observerLongitude, int observerLatitude, IPP.CelestialBody body, int dayNumber) public pure returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyTopocentricRADeclInRadians(observerLongitude, observerLatitude, body, dayNumber);
    }

    function getBodyBodyTopocentricRADeclInRadians(IPP.OrbitalElements memory orbitalElements, IPP.AxialTilt memory originAxialTilt, IPP.OrbitalElements memory newOriginOrbitalElements, int observerLongitude, int observerLatitude)  public pure returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyBodyTopocentricRADeclInRadians(orbitalElements, originAxialTilt, newOriginOrbitalElements, observerLongitude, observerLatitude);
    }




    function getBodyGeocentricRADeclNow(IPP.CelestialBody body) public view returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyGeocentricRADecl(body, getDayNumberFromTimestamp(block.timestamp));
    }

    function getBodyGeocentricRADecl(IPP.CelestialBody body, int dayNumber) public pure returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyGeocentricRADecl(body, dayNumber);
    }

    function getBodyGeocentricRADeclInRadians(IPP.CelestialBody body, int dayNumber) public pure returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyGeocentricRADeclInRadians(body, dayNumber);
    }

    function getBodyBodycentricRADeclInRadians(IPP.OrbitalElements memory orbitalElements, IPP.AxialTilt memory originAxialTilt, IPP.OrbitalElements memory newOriginOrbitalElements) public pure returns (int rightAscension, int declination, uint distance) {
        return PPL.getBodyBodycentricRADeclInRadians(orbitalElements, originAxialTilt, newOriginOrbitalElements);
    }




    function getBodyEclipticLonLatNow(IPP.CelestialBody body) public view returns (int longitude, int latitude, uint distance) {
        return PPL.getBodyEclipticLonLat(body, getDayNumberFromTimestamp(block.timestamp));
    }

    function getBodyEclipticLonLat(IPP.CelestialBody body, int dayNumber) public pure returns (int longitude, int latitude, uint distance) {
        return PPL.getBodyEclipticLonLat(body, dayNumber);
    }

    function getBodyEclipticLonLatInRadians(IPP.CelestialBody body, int dayNumber) public pure returns (int longitude, int latitude, uint distance) {
        return PPL.getBodyEclipticLonLatInRadians(body, dayNumber);
    }

    function getBodyEclipticLonLatInRadians(IPP.OrbitalElements memory orbitalElements) public pure returns (int longitude, int latitude, uint distance) {
        return PPL.getBodyEclipticLonLatInRadians(orbitalElements);
    }




    function getLocalSiderealTime(int longitude, int dayNumber) public pure returns (int siderealTime) {
        return PPL.getLocalSiderealTime(longitude, dayNumber);
    }

    function getLocalSiderealTimeInRadians(int longitude, int dayNumber) public pure returns (int siderealTime) {
        return PPL.getLocalSiderealTimeInRadians(longitude, dayNumber);
    }




    function getOrbitalElements(IPP.CelestialBody body, int dayNumber) public pure returns (IPP.OrbitalElements memory elements) {
        return PPL.getOrbitalElements(body, dayNumber);
    }

    function getOrbitalElements(IPP.OrbitalElementsParameters memory elementsParameters, int dayNumber) public pure returns (IPP.OrbitalElements memory elements) {
        return PPL.getOrbitalElements(elementsParameters, dayNumber);
    }

    function getOrbitalElementsParameters(IPP.CelestialBody body) public pure returns (IPP.OrbitalElementsParameters memory elementsParameters) {
        return PPL.getOrbitalElementsParameters(body);
    }
}