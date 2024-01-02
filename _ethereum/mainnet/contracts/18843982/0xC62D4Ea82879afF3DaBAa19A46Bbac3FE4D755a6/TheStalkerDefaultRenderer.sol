// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// the stalker by int.art
// a permissionless collaboration program running on EVM.

// Simple renderer for the stalker. Output is CC0.

import "./Base64.sol";
import "./LibString.sol";

import "./TheStalkerCommon.sol";

contract TheStalkerDefaultRenderer is ITheStalkerRenderer {
    string public theStalkerLogo =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" shape-rendering="crispEdges"><rect width="10" height="10" fill="#fff"/><g transform="translate(4.35, 4) scale(0.2,0.2)"><path stroke="#000000" d="M1 0h5M0 1h1M6 1h1M0 2h1M6 2h1M0 3h1M4 3h3M0 4h1M6 4h1M0 5h3M6 5h1M0 6h1M6 6h1M0 7h1M6 7h1M1 8h5" /></g></svg>';

    error HTMLNotSupported();

    function canUpdateToken(
        address /*sender*/,
        uint256 /*tokenId*/,
        uint256 /*targetTokenId*/
    ) public pure override returns (bool) {
        return true;
    }

    function isTokenRenderable(
        uint256 /*tokenId*/,
        uint256 /*targetTokenId*/
    ) public pure override returns (bool) {
        return true;
    }

    function tokenHTML(
        uint256 /*tokenId*/,
        uint256 /*targetTokenId*/
    ) public pure override returns (string memory) {
        revert HTMLNotSupported();
    }

    function tokenImage(
        uint256 /*tokenId*/,
        uint256 /*targetTokenId*/
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(theStalkerLogo))
                )
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint256 targetTokenId
    ) public view override returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{"name":"the stalker #',
            LibString.toString(tokenId),
            '", "description":"[no collab found]","image":"',
            tokenImage(tokenId, targetTokenId),
            '"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }
}
