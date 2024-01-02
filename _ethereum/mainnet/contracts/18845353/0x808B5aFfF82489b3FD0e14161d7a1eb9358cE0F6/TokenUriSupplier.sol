// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ITokenUriSupplier.sol";
import "./Strings.sol";

abstract contract CNCSBTTokenUriSupplier is CNCSBTITokenUriSupplier {
    using CNCSBTStrings for uint256;

    // ==================================================================
    // Variables
    // ==================================================================
    CNCSBTITokenUriSupplier public externalSupplier;

    string public baseURI = "";
    string public baseExtension = ".json";

    // ==================================================================
    // Functions
    // ==================================================================
    function tokenURI(uint256 tokenId) public virtual view returns (string memory) {
        return
            address(externalSupplier) != address(0)
                ? externalSupplier.tokenURI(tokenId)
                : _defaultTokenUri(tokenId);
    }

    function _defaultTokenUri(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
            );
    }

    function setBaseURI(string memory _value) external virtual;

    function setBaseExtension(string memory _value) external virtual;

    function setExternalSupplier(address value) external virtual;
}
