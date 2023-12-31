// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

abstract contract Setter {
    function addAuthorization(address) public virtual;

    function removeAuthorization(address) public virtual;

    function setPerBlockAllowance(address, uint256) external virtual;

    function setTotalAllowance(address, uint256) external virtual;
}

contract EnableController {
    // new contracts
    address public constant GEB_COIN_ETH_UNIV3_TWAP =
        0xc380c6640FB0562A101AAf6862f278c0A172e067;
    address public constant GEB_ETH_USD_CHAINLINK_TWAP =
        0x0d7b4A10dFF52e85e9FB7e1b030C8c2dD96E0AdD;
    address public constant GEB_INCENTIVES_COIN_TWAP_RATE_SETTER =
        0xB5e4196291cDA44329DBe70C1418747917ec813b;

    // replacing contracts (replacing same name contracts on changelog)
    address public constant GEB_RRFM_CALCULATOR =
        0x1F093C8a9D278E847abDf0ad0E6fE7EF85768423;
    address public constant GEB_RRFM_SETTER =
        0x98820Ba03E8dbC8614509685e88aa3035640EcA1;
    address public constant SYSTEM_COIN_ORACLE =
        0xC8078539f56ae8E0e3741BAa8F8Ed939D63976a8; // converter feed

    // existing
    Setter public constant GEB_ORACLE_RELAYER =
        Setter(0x6aa9D2f366beaAEc40c3409E5926e831Ea42DC82);
    Setter public constant GEB_STABILITY_FEE_TREASURY =
        Setter(0xB3c5866f6690AbD50536683994Cc949697a64cd0);

    // deprecating
    address public constant GEB_RRFM_SETTER_RELAYER =
        0x0c730fb9f17b4E8Aa721C66e2E096d5c20d500c2; // old rate setter relayer

    function run() external {
        // detatch old controller
        GEB_ORACLE_RELAYER.removeAuthorization(GEB_RRFM_SETTER_RELAYER);

        // attach new controller
        GEB_ORACLE_RELAYER.addAuthorization(GEB_RRFM_SETTER);

        // setup incentive allowance
        GEB_STABILITY_FEE_TREASURY.setPerBlockAllowance(
            address(GEB_INCENTIVES_COIN_TWAP_RATE_SETTER),
            100 * 10**45
        );
        GEB_STABILITY_FEE_TREASURY.setTotalAllowance(
            address(GEB_INCENTIVES_COIN_TWAP_RATE_SETTER),
            type(uint).max
        );
    }
}