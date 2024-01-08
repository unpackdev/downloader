// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./ICryptoPunks.sol";
import "./IWrappedPunk.sol";
import "./IMoonCatsWrapped.sol";
import "./IMoonCatsRescue.sol";
import "./IMoonCatAcclimator.sol";
import "./IERC721.sol";

library Converter {

    struct MoonCatDetails {
        bytes5[] catIds;
        uint256[] oldTokenIds;
        uint256[] rescueOrders;
    }

    /**
    * @dev converts uint256 to a bytes(32) object
    */
    function _uintToBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /**
    * @dev converts address to a bytes(32) object
    */
    function _addressToBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function mooncatToAcclimated(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.catIds.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract
            IMoonCatsRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i], 
                0, 
                0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69
            );
        }
        // mint Acclimated​MoonCats
        IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).batchWrap(moonCatDetails.rescueOrders);
    }

    function wrappedToAcclimated(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.oldTokenIds.length; i++) {
            // transfer the token to Acclimated​MoonCats to mint
            IERC721(0x7C40c393DC0f283F318791d746d894DdD3693572).safeTransferFrom(
                address(this),
                0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69,
                moonCatDetails.oldTokenIds[i],
                abi.encodePacked(
                    _uintToBytes(moonCatDetails.rescueOrders[i]),
                    _addressToBytes(address(this))
                )
            );
        }
    }

    function mooncatToWrapped(MoonCatDetails memory moonCatDetails) external {
        for (uint256 i = 0; i < moonCatDetails.catIds.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract               
            IMoonCatsRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i], 
                0, 
                0x7C40c393DC0f283F318791d746d894DdD3693572
            );
            // mint Wrapped Mooncat
            IMoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572).wrap(moonCatDetails.catIds[i]);
        }
    }

    function acclimatedToWrapped(MoonCatDetails memory moonCatDetails) external {
        // unwrap Acclimated​MoonCats to get Mooncats
        IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).batchUnwrap(moonCatDetails.rescueOrders);
        // Convert Mooncats to Wrapped Mooncats
        for (uint256 i = 0; i < moonCatDetails.rescueOrders.length; i++) {
            // make an adoption offer to the Acclimated​MoonCats contract               
            IMoonCatsRescue(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69).makeAdoptionOfferToAddress(
                moonCatDetails.catIds[i], 
                0, 
                0x7C40c393DC0f283F318791d746d894DdD3693572
            );
            // mint Wrapped Mooncat
            IMoonCatsWrapped(0x7C40c393DC0f283F318791d746d894DdD3693572).wrap(moonCatDetails.catIds[i]);
        }
    }

    function cryptopunkToWrapped(address punkProxy, uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // transfer the CryptoPunk to the userProxy
            ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB).transferPunk(punkProxy, tokenIds[i]);
            // mint Wrapped CryptoPunk
            IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).mint(tokenIds[i]);
        }
    }

    function wrappedToCryptopunk(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).burn(tokenIds[i]);
        }
    }
}