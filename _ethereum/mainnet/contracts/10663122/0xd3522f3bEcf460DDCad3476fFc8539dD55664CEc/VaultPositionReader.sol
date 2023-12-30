// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./IDssCdpManager.sol";
import "./IDssProxyActions.sol";
import "./DssActionsBase.sol";

import "./ICurveFiCurve.sol";

import "./Constants.sol";

contract VaultPositionReader {
    using SafeMath for uint256;

    uint256 constant RAY = 10**27;

    function _getSuppliedAndBorrowed(
        address vat,
        address usr,
        address urn,
        bytes32 ilk
    ) internal view returns (uint256, uint256) {
        // Gets actual rate from the vat
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Gets actual art value of the urn
        (uint256 supplied, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Gets actual dai amount in the urn
        uint256 dai = VatLike(vat).dai(usr);

        uint256 rad = art.mul(rate).sub(dai);
        uint256 wad = rad / RAY;

        // If the rad precision has some dust, it will need to request for 1 extra wad wei
        uint256 borrowed = wad.mul(RAY) < rad ? wad + 1 : wad;

        // Note that supplied is in 18 decimals, so you'll need to convert it back
        // i.e. supplied = supplied / 10 ** (18 - decimals)

        return (supplied, borrowed);
    }

    function getVaultStats(uint256 cdp)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IDssCdpManager manager = IDssCdpManager(Constants.CDP_MANAGER);

        address vat = manager.vat();
        address urn = manager.urns(cdp);
        bytes32 ilk = manager.ilks(cdp);
        address owner = manager.owns(cdp);

        // Get global stability fee
        (uint256 duty, ) = JugLike(Constants.MCD_JUG).ilks(ilk);

        (uint256 supplied, uint256 borrowed) = _getSuppliedAndBorrowed(
            vat,
            owner,
            urn,
            ilk
        );

        return (duty, supplied, borrowed);
    }
}
