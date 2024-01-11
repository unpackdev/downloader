/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./BytesUtils.sol";

contract ThreeHexSimpleRenderer {
    using BytesUtils for uint256;

    /// @param tokenId The tokenID to retrieve the URI of in
    /// format <baseURI>/<tokenId-as-hex-string>
    function render(uint256 tokenId, string calldata baseURI)
        public
        view
        virtual
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, tokenId.toHexString3())
                : "";
    }
}
