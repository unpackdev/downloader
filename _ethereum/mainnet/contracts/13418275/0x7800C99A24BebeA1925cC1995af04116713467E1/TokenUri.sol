//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";

contract TokenUri {
    using Strings for uint256;

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://api.wildsteves.xyz/metadata/",
                    tokenId.toString()
                )
            );
    }
}
