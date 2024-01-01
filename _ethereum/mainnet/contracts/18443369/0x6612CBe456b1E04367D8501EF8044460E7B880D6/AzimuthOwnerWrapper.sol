pragma solidity ^0.8.18;

import "./Interfaces.sol";

// Used as a stable contract that returns ownerOf for the Azimuth point system
// (Ecliptic supports ownerOf but selfdestructs on upgrade, and Azimuth remains stable but doesn't support ownerOf)
contract AzimuthOwnerWrapper {
    IAzimuth public azimuthContract;
    constructor(IAzimuth _azimuthContract) {
        azimuthContract = _azimuthContract;
    }
    function eclipticContract()
        public
        view
        returns(IEcliptic eclipticContract)
    {
        return IEcliptic(azimuthContract.owner());
    }

    function ownerOf(uint256 tokenId) external view returns (address owner) {
        return eclipticContract().ownerOf(tokenId);
    }
}