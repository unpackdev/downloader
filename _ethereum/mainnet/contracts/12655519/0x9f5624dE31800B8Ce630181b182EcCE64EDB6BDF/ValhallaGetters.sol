// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./Valhalla.sol";

contract ValhallaGetters is Initializable {
    address adminAddress;
    Valhalla valhalla;

    function initialize(address _adminAddress, address _valhallaAddress) public initializer {
        adminAddress = _adminAddress;
        valhalla = Valhalla(_valhallaAddress);
    }

    function getAllTokenIds() public view returns (uint256[] memory tokenIds) {
        uint256 nTokens = valhalla.totalSupply();
        tokenIds = new uint256[](nTokens);
        for (uint256 i = 0; i < nTokens; i++) {
            tokenIds[i] = valhalla.tokenByIndex(i);
        }
    }

    /**
     * Returns a list of structs of planets and owners. Throws if any planet
     * doesn't exist.
     */
    function bulkGetPlanetsByIds(uint256[] memory ids)
        public
        view
        returns (ValhallaPlanetWithMetadata[] memory planets)
    {
        planets = new ValhallaPlanetWithMetadata[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            planets[i] = valhalla.getPlanetWithMetadata(ids[i]);
        }
    }
}
