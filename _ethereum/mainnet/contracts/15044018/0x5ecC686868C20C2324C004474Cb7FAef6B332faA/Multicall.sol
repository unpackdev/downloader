// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./MarketLib.sol";
import "./DigitalCertLib.sol";
import "./IDigitalCert.sol";
import "./IMarket.sol";

contract SuperXMulticall {

    IDigitalCert digitalCert;
    IMarket market;

    constructor(address digitalCertAddress, address marketAddress) {
        digitalCert = IDigitalCert(digitalCertAddress);
        market = IMarket(marketAddress);
    }

    function getRedeemByRedeemIdMulticall(uint256[] memory ids) public view returns(MarketLib.Redeemed[] memory) {
        MarketLib.Redeemed[] memory redeems = new MarketLib.Redeemed[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {
             MarketLib.Redeemed memory redeem = market.getRedeemByRedeemId(ids[i]);
             redeems[i] = redeem;
        }
        return redeems;
    }

    function getRedeemByRedeemerAddress(address redeemer) public view returns (MarketLib.Redeemed[] memory) {
        uint256[] memory ids = market.getRedeemIdsByAddress(redeemer);
        MarketLib.Redeemed[] memory redeems = new MarketLib.Redeemed[](ids.length);
        if (ids.length <= 0) {
            return redeems;
        }
        redeems = getRedeemByRedeemIdMulticall(ids);
        return redeems;
    }

    function getDigitalCertificateById(uint256 id) public view returns(DigitalCertLib.DigitalCertificateRes memory) {
        DigitalCertLib.DigitalCertificateRes memory cert = digitalCert.getDigitalCertificate(id, address(market));
        cert.isPaused = market.isDigitalCertPaused(id);
        return cert;
    }

    function getDigitalCertificateByIdMulticall(uint256[] calldata ids) public view returns(DigitalCertLib.DigitalCertificateRes[] memory) {
        DigitalCertLib.DigitalCertificateRes[] memory certs = new  DigitalCertLib.DigitalCertificateRes[](ids.length);
        for(uint256 i = 0; i < ids.length; i++) {
            DigitalCertLib.DigitalCertificateRes memory cert = getDigitalCertificateById(ids[i]);
            certs[i] = cert;
        }
        return certs;
    }

}
